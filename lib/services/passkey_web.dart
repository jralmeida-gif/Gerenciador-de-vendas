import 'dart:js_interop';

@JS('gestorRegisterPasskey')
external JSPromise<JSBoolean> _registerPasskey(JSString nickname);

@JS('gestorPreparePasskeyRegistration')
external JSPromise<JSString> _preparePasskeyRegistration();

@JS('gestorRegisterPreparedPasskey')
external JSPromise<JSBoolean> _registerPreparedPasskey(JSString prepared, JSString nickname);

@JS('gestorLoginPasskey')
external JSPromise<JSString> _loginPasskey(JSString username);

class PasskeyService {
  static bool get supported => true;

  static Future<String> prepareRegistration() async {
    return (await _preparePasskeyRegistration().toDart).toDart;
  }

  static Future<bool> registerPrepared(String prepared, {String nickname = 'Este dispositivo'}) async {
    return (await _registerPreparedPasskey(prepared.toJS, nickname.toJS).toDart).toDart;
  }

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
