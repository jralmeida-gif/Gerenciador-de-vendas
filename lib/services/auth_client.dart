import 'dart:convert';

import 'package:http/browser_client.dart';

class AuthUser {
  final String id;
  final String username;
  final String role;
  final bool mustChangePassword;

  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.mustChangePassword,
  });
  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    username: json['username'] as String,
    role: json['role'] as String,
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  );
}

class AuthResult {
  final bool ok;
  final String? error;
  final AuthUser? user;
  const AuthResult({required this.ok, this.error, this.user});
}

class SessionCheckResult {
  final bool reachable;
  final AuthUser? user;
  const SessionCheckResult({required this.reachable, this.user});
}

class PasswordResetResult {
  final bool accepted;
  final String message;
  final String? recipient;
  final String? deliveryStatus;
  final String? deliveryReason;
  const PasswordResetResult({
    required this.accepted,
    required this.message,
    this.recipient,
    this.deliveryStatus,
    this.deliveryReason,
  });
}

class AuthClient {
  final BrowserClient _client = BrowserClient()..withCredentials = true;
  String get _origin => Uri.base.origin;

  Future<bool> setupRequired() async {
    try {
      final response = await _client.get(Uri.parse('$_origin/api/auth/status'));
      return response.statusCode == 200 &&
          (jsonDecode(response.body)['setupRequired'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<SessionCheckResult> checkSession() async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$_origin/api/auth/session?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: {'Cache-Control': 'no-cache'},
      );
      if (response.statusCode != 200) {
        return const SessionCheckResult(reachable: false);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['authenticated'] != true) {
        return const SessionCheckResult(reachable: true);
      }
      return SessionCheckResult(
        reachable: true,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
    } catch (_) {
      return const SessionCheckResult(reachable: false);
    }
  }

  Future<AuthUser?> session() async => (await checkSession()).user;

  Future<AuthResult> login(String username, String password) async {
    return _postUser('/api/auth/login', {
      'username': username,
      'password': password,
    });
  }

  Future<AuthResult> registerFirst(String username, String password) async {
    return _postUser('/api/auth/register-first', {
      'username': username,
      'password': password,
    });
  }

  Future<PasswordResetResult> requestPasswordReset(String username) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/auth/request-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username.trim()}),
      );
      final body = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final message = (body['message'] ?? body['error'])?.toString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final delivery = body['delivery'] is Map<String, dynamic>
            ? body['delivery'] as Map<String, dynamic>
            : const <String, dynamic>{};
        return PasswordResetResult(
          accepted: true,
          message: message ?? 'A solicitação foi aceita pela Mailjet.',
          recipient: delivery['recipient']?.toString(),
          deliveryStatus: delivery['status']?.toString(),
          deliveryReason: delivery['reason']?.toString(),
        );
      }
      return PasswordResetResult(
        accepted: false,
        message: message ?? 'Não foi possível solicitar a recuperação.',
      );
    } catch (_) {
      return const PasswordResetResult(
        accepted: false,
        message: 'Não foi possível conectar ao servidor.',
      );
    }
  }

  Future<String?> resetPassword(String token, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error']?.toString() ?? 'Não foi possível redefinir a senha.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      return (jsonDecode(response.body) as Map<String, dynamic>)['error']
              ?.toString() ??
          'Não foi possível trocar a senha.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> verificarSenha(String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/auth/verify-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      final body = response.body.trim().isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      return body['error']?.toString() ?? 'Não foi possível confirmar a senha.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> executarLimpezaGlobal({
    required String password,
    required String masterPassword,
    required bool catalogo,
    required bool dadosUsuario,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/admin/global-cleanup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': password,
          'masterPassword': masterPassword,
          'catalogo': catalogo,
          'dadosUsuario': dadosUsuario,
        }),
      );
      final body = response.body.trim().isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      return body['error']?.toString() ??
          'Não foi possível executar a limpeza global.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> enviarFeedback({
    required String tipo,
    String assunto = '',
    required String mensagem,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipo': tipo,
          'assunto': assunto.trim(),
          'mensagem': mensagem.trim(),
        }),
      );
      final body = response.body.trim().isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      return body['error']?.toString() ?? 'Não foi possível enviar a mensagem.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<List<Map<String, dynamic>>> listAdminActivities({int limit = 100}) async {
    final safeLimit = limit.clamp(1, 200);
    final response = await _client.get(
      Uri.parse('$_origin/api/admin/activity?limit=$safeLimit'),
    );
    if (response.statusCode != 200) {
      final body = response.body.trim().isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        body['error']?.toString() ?? 'Não foi possível carregar o histórico.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['activities'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    final response = await _client.get(Uri.parse('$_origin/api/auth/users'));
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar os usuários.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['users'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<String?> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin/api/auth/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      return (jsonDecode(response.body) as Map<String, dynamic>)['error']
              ?.toString() ??
          'Não foi possível cadastrar o usuário.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> updateUser({
    required String id,
    String? displayName,
    String? role,
    bool? active,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{'id': id};
      if (displayName != null) body['displayName'] = displayName;
      if (role != null) body['role'] = role;
      if (active != null) body['active'] = active;
      if (password != null) body['password'] = password;
      final response = await _client.patch(
        Uri.parse('$_origin/api/auth/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      return (jsonDecode(response.body) as Map<String, dynamic>)['error']
              ?.toString() ??
          'Não foi possível alterar o usuário.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> deleteUser(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_origin/api/auth/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      return (jsonDecode(response.body) as Map<String, dynamic>)['error']
              ?.toString() ??
          'Não foi possível excluir o usuário.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  Future<void> logout({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      await _client
          .post(
            Uri.parse(
              '$_origin/api/auth/logout?t=${DateTime.now().millisecondsSinceEpoch}',
            ),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(timeout);
    } catch (_) {
      // O logout local não pode ficar bloqueado por uma rede indisponível.
    }
  }

  Future<AuthResult> _postUser(String path, Map<String, String> body) async {
    try {
      final response = await _client.post(
        Uri.parse('$_origin$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['user'] is Map<String, dynamic>) {
        return AuthResult(
          ok: true,
          user: AuthUser.fromJson(decoded['user'] as Map<String, dynamic>),
        );
      }
      return AuthResult(
        ok: false,
        error:
            decoded['error']?.toString() ??
            'Não foi possível concluir a operação.',
      );
    } catch (_) {
      return const AuthResult(
        ok: false,
        error: 'Não foi possível conectar ao servidor.',
      );
    }
  }
}
