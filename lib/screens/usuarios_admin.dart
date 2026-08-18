import 'package:flutter/material.dart';

import '../services/auth_client.dart';

class TelaUsuariosAdmin extends StatefulWidget {
  const TelaUsuariosAdmin({super.key});

  @override
  State<TelaUsuariosAdmin> createState() => _TelaUsuariosAdminState();
}

class _TelaUsuariosAdminState extends State<TelaUsuariosAdmin> {
  final _auth = AuthClient();
  List<Map<String, dynamic>> _users = [];
  AuthUser? _currentUser;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_auth.listUsers(), _auth.session()]);
      _users = results[0] as List<Map<String, dynamic>>;
      _currentUser = results[1] as AuthUser?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _newUser() async {
    final username = TextEditingController();
    final password = TextEditingController();
    String role = 'user';
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Cadastrar usuário'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: username, decoration: const InputDecoration(labelText: 'Usuário ou e-mail')),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha temporária')),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Perfil'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Usuário comum')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (value) { if (value != null) setDialog(() => role = value); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, (username.text, password.text, role)), child: const Text('Cadastrar')),
          ],
        ),
      ),
    );
    username.dispose();
    password.dispose();
    if (result == null) return;
    final error = await _auth.createUser(username: result.$1, password: result.$2, role: result.$3);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário cadastrado. A troca da senha será exigida no primeiro acesso.')));
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final alias = TextEditingController(text: (user['display_name'] ?? '').toString());
    String role = user['role'] == 'admin' ? 'admin' : 'user';
    bool active = user['active'] == 1;
    final result = await showDialog<(String, String, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Editar usuário'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Identificador de login: ${user['username']}', style: const TextStyle(color: Colors.black54)),
            TextField(controller: alias, decoration: const InputDecoration(labelText: 'Alias')),
            DropdownButtonFormField<String>(initialValue: role, decoration: const InputDecoration(labelText: 'Perfil'), items: const [DropdownMenuItem(value: 'user', child: Text('Usuário comum')), DropdownMenuItem(value: 'admin', child: Text('Administrador'))], onChanged: (value) { if (value != null) setDialog(() => role = value); }),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Acesso ativo'), value: active, onChanged: (value) => setDialog(() => active = value)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, (alias.text, role, active)), child: const Text('Salvar'))],
        ),
      ),
    );
    alias.dispose();
    if (result == null) return;
    final error = await _auth.updateUser(id: user['id'].toString(), displayName: result.$1.trim(), role: result.$2, active: result.$3);
    await _finishAction(error, 'Usuário atualizado.');
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir senha temporária'),
        content: TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Nova senha temporária', helperText: 'O usuário deverá trocá-la no próximo acesso.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Redefinir'))],
      ),
    );
    if (confirmed != true) { password.dispose(); return; }
    final error = await _auth.updateUser(id: user['id'].toString(), password: password.text);
    password.dispose();
    await _finishAction(error, 'Senha redefinida. O usuário deverá criar uma nova no próximo acesso.');
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir usuário?'),
        content: Text('A conta de ${user['username']} e todos os dados vinculados a ela serão excluídos. Esta ação não pode ser desfeita.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))],
      ),
    );
    if (confirmed != true) return;
    final error = await _auth.deleteUser(user['id'].toString());
    await _finishAction(error, 'Usuário excluído.');
  }

  Future<void> _finishAction(String? error, String success) async {
    if (error == null) {
      await _load();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? success)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Usuários')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _newUser, icon: const Icon(Icons.person_add_alt_1), label: const Text('Novo usuário')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            const Text('Somente administradores podem cadastrar, editar, redefinir senhas ou excluir acessos.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ..._users.map((u) {
              final isSelf = _currentUser?.id == u['id'];
              final alias = (u['display_name'] ?? '').toString().trim();
              return Card(
                child: ListTile(
                  leading: Icon(u['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person_outline),
                  title: Text(alias.isEmpty ? u['username'].toString() : alias),
                  subtitle: Text('${u['username']} · ${u['role'] == 'admin' ? 'Administrador' : 'Usuário comum'}${isSelf ? ' · Você' : ''}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) { if (action == 'edit') _editUser(u); if (action == 'password') _resetPassword(u); if (action == 'delete') _deleteUser(u); },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar usuário'))),
                      const PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.lock_reset_outlined), title: Text('Redefinir senha'))),
                      if (!isSelf) const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Excluir usuário'))),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
  );
}
