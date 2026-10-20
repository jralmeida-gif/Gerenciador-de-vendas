import 'dart:js_interop';

@JS('gestorRegisterPasskey')
external JSPromise<JSBoolean> _registerPasskey(JSString nickname);

@JS('gestorLoginPasskey')
external JSPromise<JSString> _loginPasskey(JSString username);

class PasskeyService {
  static bool get supported => true;

  static Future<bool> register({String nickname = 'Este dispositivo'}) async {
    try {
      return (await _registerPasskey(nickname.toJS).toDart).toDart;
    } catch (_) {
      rethrow;
    }
  }

  static Future<String?> login(String username) async {
    try {
      return (await _loginPasskey(username.trim().toJS).toDart).toDart;
    } catch (_) {
      rethrow;
    }
  }
}
