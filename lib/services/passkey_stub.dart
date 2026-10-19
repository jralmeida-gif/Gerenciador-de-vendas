class PasskeyService {
  static bool get supported => false;
  static Future<bool> register({String nickname = 'Este dispositivo'}) async => false;
  static Future<String?> login(String username) async => null;
}
