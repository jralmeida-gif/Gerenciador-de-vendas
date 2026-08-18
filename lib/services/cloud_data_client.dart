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

  Future<Map<String, dynamic>?> loadCatalog() async {
    try {
      final response = await _client.get(Uri.parse('$_origin/api/catalog'));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> && body['ok'] == true ? body : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveCatalog({
    required String entity,
    required String action,
    String? oldName,
    required String name,
    String? format,
    String? code,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/admin/catalog'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'entity': entity,
          'action': action,
          if (oldName != null) 'oldName': oldName,
          'name': name,
          if (format != null) 'format': format,
          if (code != null) 'code': code,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      final body = response.body.trim().isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
      return body['error']?.toString() ?? 'Não foi possível atualizar o catálogo mestre.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }
}
