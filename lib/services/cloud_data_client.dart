import 'dart:convert';

import 'package:http/browser_client.dart';

class CloudDataClient {
  final BrowserClient _client = BrowserClient()..withCredentials = true;
  String get _origin => Uri.base.origin;

  Future<String?> load() async {
    try {
      final response = await _client.get(Uri.parse('$_origin/api/data'));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['ok'] != true) return null;
      final data = Map<String, dynamic>.from(body)..remove('ok');
      return jsonEncode(data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> save(String backupJson) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/data'),
        headers: {'Content-Type': 'application/json'},
        body: backupJson,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
