class PushClient {
  static Future<bool> isSupported() async => false;

  static Future<bool> enable() async => false;

  static Future<void> syncRecords({
    required List<Map<String, dynamic>> portabilidades,
    required List<Map<String, dynamic>> prospeccoes,
  }) async {}
}
