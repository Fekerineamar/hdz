import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Reads the SSO SMS verification code off the device.
///
/// Two strategies, tried together:
///  1. A native `BroadcastReceiver` (RECEIVE_SMS) surfaced through an
///     EventChannel — works for any SMS but needs the SMS permission.
///  2. `sms_autofill` (SMS Retriever API) — no permission, works only when the
///     sender appends the app hash. Best-effort.
class SmsService {
  SmsService._() {
    _eventChannel = const EventChannel('dzds_agent/sms_events');
    _methodChannel = const MethodChannel('dzds_agent/sms');
  }
  static final SmsService instance = SmsService._();

  late final EventChannel _eventChannel;
  late final MethodChannel _methodChannel;

  final _autoFill = SmsAutoFill();
  StreamSubscription<String>? _nativeSub;
  StreamSubscription<String>? _autoSub;

  final _controller = StreamController<String>.broadcast();
  Stream<String> get codes => _controller.stream;

  static final _codeRegex = RegExp(r'\b(\d{4,6})\b');

  void start() {
    // Native receiver stream.
    _nativeSub = _eventChannel
        .receiveBroadcastStream()
        .map((e) => '$e')
        .where((e) => e.isNotEmpty)
        .listen((raw) => _emit(_extract(raw)));

    // SMS Retriever fallback.
    _autoFill.listenForCode().catchError((_) {});
    _autoSub = _autoFill.code.listen(_emit);
  }

  Future<String> appSignature() async => _autoFill.getAppSignature;

  Future<bool> hasPermission() async {
    try {
      return await _methodChannel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _methodChannel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  void _emit(String? code) {
    if (code != null && code.isNotEmpty) {
      if (!_controller.isClosed) _controller.add(code);
    }
  }

  String? _extract(String raw) {
    final m = _codeRegex.firstMatch(raw);
    return m?.group(0);
  }

  void dispose() {
    _nativeSub?.cancel();
    _autoSub?.cancel();
    _autoFill.unregisterListener();
    _controller.close();
  }
}
