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
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { _users = await _auth.listUsers(); } catch (_) {} if (mounted) setState(() => _loading = false); }
  Future<void> _newUser() async {
    final username = TextEditingController(); final password = TextEditingController(); String role = 'user';
    final result = await showDialog<(String, String, String)>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(title: const Text('Cadastrar usuário'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: username, decoration: const InputDecoration(labelText: 'Usuário ou e-mail @caixa.gov.br')), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha temporária')), DropdownButtonFormField<String>(initialValue: role, decoration: const InputDecoration(labelText: 'Perfil'), items: const [DropdownMenuItem(value: 'user', child: Text('Usuário comum')), DropdownMenuItem(value: 'admin', child: Text('Administrador'))], onChanged: (value) { if (value != null) setDialog(() => role = value); })]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, (username.text, password.text, role)), child: const Text('Cadastrar'))])));
    if (result == null) return;
    final error = await _auth.createUser(username: result.$1, password: result.$2, role: result.$3);
    if (!mounted) return;
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário cadastrado. A troca da senha será exigida no primeiro acesso.')));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Usuários')), floatingActionButton: FloatingActionButton.extended(onPressed: _newUser, icon: const Icon(Icons.person_add_alt_1), label: const Text('Novo usuário')), body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [const Text('Somente administradores podem cadastrar ou alterar acessos.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 12), ..._users.map((u) => Card(child: ListTile(leading: Icon(u['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person_outline), title: Text('${u['username']}@caixa.gov.br'), subtitle: Text(u['role'] == 'admin' ? 'Administrador' : 'Usuário comum'), trailing: Text(u['active'] == 1 ? 'Ativo' : 'Inativo'))))]));
}
