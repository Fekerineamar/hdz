import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini client that talks to the raw REST API (instead of the SDK's
/// `startChat`), because Gemini 3.x changed the function-calling protocol:
///
///  * model turns must carry the `functionCall` **and** its `functionResponse`
///    together in a single `role: "model"` content (the legacy `"function"`
///    role is rejected), and
///  * each `functionCall` part must echo back its `thoughtSignature` and `id`,
///    which the official SDK drops.
class GeminiService {
  GeminiService({
    required String apiKey,
    required String systemInstruction,
    List<Tool>? tools,
    String model = 'gemini-3.6-flash',
    List<String> fallbackModels = const [
      'gemini-3-flash-preview',
      'gemini-3.8-flash',
      'gemini-3.7-flash',
      'gemini-3.5-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemini-3.1-flash-lite-preview',
      'gemini-flash-latest',
      'gemini-flash-lite-latest',
      'gemini-omni-flash-preview',
      'gemini-omni-1.1-flash',
    ],
  })  : _apiKey = apiKey,
        _systemInstruction = systemInstruction,
        _tools = tools ?? const [],
        _models = <String>[
          model,
          for (final m in fallbackModels)
            if (m != model) m,
        ];

  final String _apiKey;
  final String _systemInstruction;
  final List<Tool> _tools;

  /// Ordered models to try. The first is the configured primary; the rest are
  /// used automatically when the primary is quota-limited or overloaded.
  final List<String> _models;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));

  final List<Map<String, Object?>> _history = [];
  List<Map<String, Object?>> _pendingCallParts = [];

  String _endpointFor(String model) =>
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$_apiKey';

  /// Send a text message; returns the model's text and any function calls.
  Future<AgentTurn> sendText(String text) async {
    _history.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ],
    });
    return _generate();
  }

  /// Send function results back to the model.
  Future<AgentTurn> sendFunctionResponses(
      List<FunctionResponse> responses) async {
    final parts = <Map<String, Object?>>[
      ..._pendingCallParts,
      for (final r in responses)
        {
          'functionResponse': {
            'name': r.name,
            'response': r.response ?? <String, Object?>{},
          },
        },
    ];
    _history.add({'role': 'model', 'parts': parts});
    _pendingCallParts = [];
    return _generate();
  }

  Future<AgentTurn> _generate() async {
    final body = <String, Object?>{
      'contents': _history,
      'systemInstruction': {
        'parts': [
          {'text': _systemInstruction}
        ],
      },
      if (_tools.isNotEmpty) 'tools': _tools.map((t) => t.toJson()).toList(),
    };

    Map<String, dynamic>? data;
    Object? lastError;
    for (final model in _models) {
      var attempt = 0;
      while (attempt < 2) {
        attempt++;
        try {
          final res = await _dio.post(
            _endpointFor(model),
            data: body,
            options: Options(
              contentType: Headers.jsonContentType,
              headers: {'Connection': 'close'},
            ),
          );
          data = Map<String, dynamic>.from(res.data as Map);
          lastError = null;
          break;
        } on DioException catch (e) {
          lastError = e;
          final code = e.response?.statusCode;
          if (code == 429) {
            // Quota or per-minute rate limit: this model won't recover soon,
            // so move to the next model immediately.
            print('[GEMINI] $model -> 429, trying next model');
            break;
          }
          if (code == 503 || code == 502 || code == 504 || code == null) {
            // Transient overload / network failure: one quick retry, then next.
            print('[GEMINI] $model -> ${code ?? 'network error'}, retry');
            await Future<void>.delayed(const Duration(seconds: 1));
            continue;
          }
          break; // auth/bad request: not worth retrying
        }
      }
      if (data != null) break; // success, stop trying further models
    }
    if (lastError != null) {
      final e = lastError as DioException;
      throw StateError(_errorMessage(e.response?.data) ?? '$e');
    }
    final parsed = data;
    if (parsed == null) throw StateError('No Gemini model available');

    final error = parsed['error'];
    if (error is Map) {
      throw StateError('${error['message'] ?? 'Gemini error'}');
    }

    final candidates = (parsed['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) throw StateError('Empty response from Gemini');

    final content =
        Map<String, dynamic>.from((candidates.first as Map))['content'];
    final parts =
        (content is Map ? content['parts'] : null) as List? ?? const [];

    final textBuffer = StringBuffer();
    final callParts = <Map<String, Object?>>[];
    final calls = <FunctionCall>[];

    for (final raw in parts) {
      final part = Map<String, dynamic>.from(raw as Map);
      if (part.containsKey('text')) {
        textBuffer.write(part['text'] ?? '');
      } else if (part.containsKey('functionCall')) {
        final fc = Map<String, dynamic>.from(part['functionCall'] as Map);
        final name = '${fc['name'] ?? ''}';
        final args = Map<String, Object?>.from((fc['args'] as Map?) ?? {});
        calls.add(FunctionCall(name, args));
        callParts.add(Map<String, Object?>.from(part));
      }
    }

    if (calls.isNotEmpty) {
      _pendingCallParts = callParts;
      return AgentTurn(calls: calls);
    }

    if (content is Map) {
      _history.add(Map<String, Object?>.from(content));
    }
    final text = textBuffer.toString().trim();
    return AgentTurn(text: text.isEmpty ? null : text);
  }

  String? _errorMessage(Object? data) {
    if (data is Map) {
      final e = data['error'];
      if (e is Map) return '${e['message']}';
      if (data['message'] is String) return '${data['message']}';
    }
    if (data is String) {
      try {
        final m = jsonDecode(data);
        if (m is Map && m['error'] is Map) return '${m['error']['message']}';
      } catch (_) {}
    }
    return null;
  }
}

class AgentTurn {
  final String? text;
  final List<FunctionCall> calls;

  const AgentTurn({this.text, this.calls = const []});

  bool get hasCalls => calls.isNotEmpty;
}
