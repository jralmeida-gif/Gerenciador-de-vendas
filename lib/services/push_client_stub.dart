class PushClient {
  static Future<bool> isSupported() async => false;

  static Future<String> status() async => 'unsupported';

  static Future<bool> enable() async => false;

  static Future<bool> disable() async => false;

  static bool openSettings() => false;

  static Future<void> syncRecords({
    required List<Map<String, dynamic>> portabilidades,
    required List<Map<String, dynamic>> prospeccoes,
    required List<Map<String, dynamic>> clientes,
  }) async {}
}
