import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;

@JS('gestorPushEnable')
external JSPromise<JSBoolean> _gestorPushEnable();

@JS('gestorPushStatus')
external JSPromise<JSString> _gestorPushStatus();

@JS('gestorPushDisable')
external JSPromise<JSBoolean> _gestorPushDisable();

@JS('gestorPushOpenSettings')
external JSBoolean _gestorPushOpenSettings();

class PushClient {
  static String get _baseUrl => Uri.base.origin;

  static Future<bool> isSupported() async => Uri.base.scheme == 'https';

  static Future<String> status() async {
    if (!await isSupported()) return 'unsupported';
    try {
      return (await _gestorPushStatus().toDart).toDart;
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<bool> disable() async {
    if (!await isSupported()) return false;
    try {
      return (await _gestorPushDisable().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  static bool openSettings() {
    try {
      return _gestorPushOpenSettings().toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enable() async {
    if (!await isSupported()) return false;
    try {
      final result = await _gestorPushEnable().toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncRecords({
    required List<Map<String, dynamic>> portabilidades,
    required List<Map<String, dynamic>> prospeccoes,
  }) async {
    if (!await isSupported()) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/push/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'portabilidades': portabilidades,
          'prospeccoes': prospeccoes,
        }),
      );
    } catch (_) {
      // O armazenamento local continua sendo a fonte principal; a falha de
      // rede não deve impedir o usuário de salvar um cadastro.
    }
  }
}
