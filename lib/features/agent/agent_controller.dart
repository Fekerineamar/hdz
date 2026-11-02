import 'dart:async';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_store.dart';
import '../../models/domain.dart';
import '../ai/document_extractor.dart';
import '../ai/gemini_service.dart';
import '../ai/tools.dart';
import '../auth/sms_service.dart';
import '../auth/sso_client.dart';
import '../services/portal_client.dart';

/// Events emitted to the UI while the agent runs.
sealed class AgentEvent {}

class AgentMessage extends AgentEvent {
  final String text;
  AgentMessage(this.text);
}

class AgentStatus extends AgentEvent {
  final String text;
  AgentStatus(this.text);
}

class AgentNeedCaptcha extends AgentEvent {
  final CaptchaPuzzle puzzle;
  AgentNeedCaptcha(this.puzzle);
}

class AgentNeedSms extends AgentEvent {}

class AgentNeedDocument extends AgentEvent {
  final String purpose;
  AgentNeedDocument(this.purpose);
}

class AgentDone extends AgentEvent {
  final String text;
  AgentDone(this.text);
}

class AgentError extends AgentEvent {
  final String text;
  AgentError(this.text);
}

class AgentSessionUpdated extends AgentEvent {
  final UserSession? session;
  AgentSessionUpdated(this.session);
}

/// Orchestrates the Gemini ↔ tools loop and bridges human-in-the-loop steps to
/// the UI through the [events] stream.
class AgentController {
  AgentController({String? apiKey})
      : _apiKey = apiKey != null && apiKey.isNotEmpty
            ? apiKey
            : (AppConfig.geminiApiKey.isNotEmpty
                ? AppConfig.geminiApiKey
                : null) {
    _api = ApiClient();
    _sso = SsoClient(_api);
    _portal = PortalClient(_api);
    _sms = SmsService.instance;
    _hooks = _Hooks(this);
    _executor = ToolExecutor(
      sso: _sso,
      portal: _portal,
      sms: _sms,
      hooks: _hooks,
    );
  }

  final String? _apiKey;
  late final ApiClient _api;
  late final SsoClient _sso;
  late final PortalClient _portal;
  late final SmsService _sms;
  late final _Hooks _hooks;
  late final ToolExecutor _executor;

  GeminiService? _gemini;
  final _events = StreamController<AgentEvent>.broadcast();
  UserSession? _session;

  Stream<AgentEvent> get events => _events.stream;
  UserSession? get session => _session;

  Completer<CaptchaAnswer>? _pendingCaptcha;
  Completer<String>? _pendingSms;
  Completer<DocumentData?>? _pendingDocument;

  // Incremented on every start()/stop() to invalidate in-flight turns.
  int _runId = 0;

  bool get isReady => (_apiKey?.isNotEmpty ?? false);

  /// Ensure the Gemini service is built (with tools).
  Future<void> _ensureGemini() async {
    final key = await _resolveKey();
    _gemini ??= GeminiService(
      apiKey: key,
      systemInstruction: agentSystemPrompt,
      tools: [Tool(functionDeclarations: buildToolDeclarations())],
      model: AppConfig.geminiModel,
    );
  }

  Future<String> _resolveKey() async {
    if (_apiKey != null && _apiKey.isNotEmpty) return _apiKey;
    final stored = await SecureStore.instance.geminiApiKey;
    if (stored != null && stored.isNotEmpty) return stored;
    throw StateError('Gemini API key is not configured');
  }

  /// Start the agent on a user goal.
  Future<void> start(String goal) async {
    final id = ++_runId;
    try {
      await _ensureGemini();
      _emit(AgentStatus('Thinking…'));
      var turn = await _gemini!.sendText(goal);
      if (_cancelled(id)) return;
      await _processTurn(turn, id);
    } catch (e) {
      if (_cancelled(id)) return;
      _emit(AgentError('$e'));
    }
  }

  Future<void> _processTurn(AgentTurn turn, int id) async {
    if (turn.hasCalls) {
      final responses = <FunctionResponse>[];
      for (final call in turn.calls) {
        if (_cancelled(id)) return;
        _emit(AgentStatus('Running ${call.name}…'));
        final result = await _executor.execute(call);
        if (_cancelled(id)) return;
        responses.add(FunctionResponse(call.name, result));
      }
      final next = await _gemini!.sendFunctionResponses(responses);
      if (_cancelled(id)) return;
      await _processTurn(next, id);
    } else if (turn.text != null && turn.text!.isNotEmpty) {
      _checkSessionQuietly();
      _emit(AgentDone(turn.text!));
    }
  }

  void _checkSessionQuietly() {
    _portal.session().then((s) {
      _session = s;
      _emit(AgentSessionUpdated(s));
    }).catchError((_) {});
  }

  Future<UserSession?> checkSession() async {
    try {
      final s = await _portal.session();
      _session = s;
      _emit(AgentSessionUpdated(s));
      return s;
    } catch (_) {
      return null;
    }
  }

  bool _cancelled(int id) => id != _runId;

  /// Stop the currently running agent turn. Unblocks any in-progress
  /// captcha/SMS/document prompt so the loop can wind down.
  void stop() {
    _runId++;
    _pendingCaptcha?.complete(const CaptchaAnswer(0, 0));
    _pendingCaptcha = null;
    _pendingSms?.complete('');
    _pendingSms = null;
    _pendingDocument?.complete(null);
    _pendingDocument = null;
  }

  // Human input resolution -------------------------------------------------

  void resolveCaptcha(double x, double y) {
    _pendingCaptcha?.complete(CaptchaAnswer(x, y));
    _pendingCaptcha = null;
  }

  void resolveSms(String code) {
    _pendingSms?.complete(code);
    _pendingSms = null;
  }

  void resolveDocument(DocumentData? data) {
    if (data != null) _executor.seedDocumentContext(data);
    _pendingDocument?.complete(data);
    _pendingDocument = null;
  }

  /// Extracts fields from one or more images (e.g. front and back of ID card)
  /// and feeds them to the agent context.
  Future<DocumentData> extractDocument({
    List<int>? singleBytes,
    List<List<int>>? multipleBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final key = await _resolveKey();
    final extractor = DocumentExtractor(key);
    final imagesList = <Uint8List>[];
    if (multipleBytes != null) {
      for (final b in multipleBytes) {
        imagesList.add(Uint8List.fromList(b));
      }
    }
    if (singleBytes != null && singleBytes.isNotEmpty) {
      imagesList.add(Uint8List.fromList(singleBytes));
    }
    return extractor.extract(
      imagesBytes: imagesList,
      mimeType: mimeType,
    );
  }

  /// Seeds the executor's document context directly (called from UI after a
  /// direct upload so the agent already has the fields before its first turn).
  void seedDocument(DocumentData data) {
    _executor.seedDocumentContext(data);
  }

  void dispose() {
    _events.close();
    _sms.dispose();
  }

  void _emit(AgentEvent e) {
    if (!_events.isClosed) _events.add(e);
  }
}

class _Hooks implements AgentHooks {
  _Hooks(this.controller);
  final AgentController controller;

  @override
  void log(String message) => controller._emit(AgentStatus(message));

  @override
  Future<CaptchaAnswer> solveCaptcha(CaptchaPuzzle puzzle) {
    controller._emit(AgentNeedCaptcha(puzzle));
    final c = Completer<CaptchaAnswer>();
    controller._pendingCaptcha = c;
    return c.future;
  }

  @override
  Future<String> readSmsCode() {
    controller._emit(AgentNeedSms());
    final c = Completer<String>();
    controller._pendingSms = c;
    return c.future;
  }

  @override
  Future<DocumentData?> provideDocument(String purpose) {
    controller._emit(AgentNeedDocument(purpose));
    final c = Completer<DocumentData?>();
    controller._pendingDocument = c;
    return c.future;
  }
}
