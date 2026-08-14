import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_client.dart';
import '../services/repositorio.dart';
import '../services/app_state.dart';
import '../services/session_guard.dart';
import '../theme/app_theme.dart';
import 'inicio.dart';

class AuthGate extends StatefulWidget {
  final Repositorio repo;
  const AuthGate({super.key, required this.repo});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthClient();
  AuthUser? _user;
  bool _loading = true;
  bool _setup = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user = await _auth.session();
    var setup = false;
    if (user != null) {
      await widget.repo.switchProfile(user.username);
      if (mounted) await context.read<AppState>().carregarDaNuvem();
    } else {
      setup = await _auth.setupRequired();
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _setup = setup;
      _loading = false;
    });
  }

  Future<void> _loggedIn(AuthResult result) async {
    if (!result.ok || result.user == null) { _showError(result.error ?? 'Não foi possível entrar.'); return; }
    await widget.repo.switchProfile(result.user!.username);
    if (mounted) await context.read<AppState>().carregarDaNuvem();
    if (!mounted) return;
    setState(() => _user = result.user);
  }

  void _showError(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _senhaDefinitivaSalva() async {
    final atual = _user;
    if (atual == null || !mounted) return;
    setState(() => _user = AuthUser(id: atual.id, username: atual.username, role: atual.role, mustChangePassword: false));
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final ctrl = TextEditingController(text: context.read<AppState>().nomeUsuario == 'Usuário' ? '' : context.read<AppState>().nomeUsuario);
    final alias = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Como você gostaria de ser chamado?'),
        content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome ou alias')),
        actions: [
          ElevatedButton(onPressed: () { if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim()); }, child: const Text('Salvar')),
        ],
      ),
    );
    if (alias != null && alias.isNotEmpty && mounted) await context.read<AppState>().salvarNomeUsuario(alias);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return LoginView(auth: _auth, setup: _setup, onLoggedIn: _loggedIn);
    if (_user!.mustChangePassword) return ChangePasswordView(auth: _auth, onDone: _senhaDefinitivaSalva);
    void sair() {
      unawaited(_auth.logout());
      if (mounted) setState(() => _user = null);
    }
    return SessionGuard(
      timeout: Duration(minutes: context.read<AppState>().idleTimeoutMinutes),
      onTimeout: sair,
      child: TelaInicio(user: _user!, onLogout: sair),
    );
  }
}

class LoginView extends StatefulWidget {
  final AuthClient auth;
  final bool setup;
  final Future<void> Function(AuthResult) onLoggedIn;
  const LoginView({super.key, required this.auth, required this.setup, required this.onLoggedIn});
  @override
  State<LoginView> createState() => _LoginViewState();
}
class _LoginViewState extends State<LoginView> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _busy = true);
    final result = widget.setup ? await widget.auth.registerFirst(_username.text, _password.text) : await widget.auth.login(_username.text, _password.text);
    if (mounted) setState(() => _busy = false);
    await widget.onLoggedIn(result);
  }
  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: widget.setup ? 'Configuração inicial' : 'Entrar no Gestor de Vendas',
        subtitle: widget.setup ? 'Cadastre o primeiro usuário. Ele será administrador automaticamente.' : 'Use o prefixo do e-mail ou o e-mail completo @caixa.gov.br.',
        children: [
          TextField(controller: _username, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Usuário @caixa.gov.br', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: widget.setup ? 'Senha inicial' : 'Senha', prefixIcon: const Icon(Icons.lock_outline))),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.setup ? 'Criar administrador' : 'Entrar'))),
        ],
      );
}

class ChangePasswordView extends StatefulWidget {
  final AuthClient auth;
  final VoidCallback onDone;
  const ChangePasswordView({super.key, required this.auth, required this.onDone});
  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}
class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  Future<void> _submit() async {
    if (_newPassword.text.length < 8 || _newPassword.text != _confirm.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A nova senha deve ter 8 caracteres e coincidir nos dois campos.'))); return; }
    setState(() => _busy = true);
    final error = await widget.auth.changePassword(_current.text, _newPassword.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      widget.onDone();
    }
  }
  @override
  Widget build(BuildContext context) => _AuthScaffold(title: 'Crie sua senha definitiva', subtitle: 'Por segurança, a senha temporária precisa ser trocada antes do primeiro acesso.', children: [
        TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Senha temporária')),
        const SizedBox(height: 14), TextField(controller: _newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Nova senha')),
        const SizedBox(height: 14), TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirme a nova senha')),
        const SizedBox(height: 22), SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Salvando...' : 'Salvar nova senha'))),
      ]);
}

class _AuthScaffold extends StatelessWidget {
  final String title; final String subtitle; final List<Widget> children;
  const _AuthScaffold({required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(subtitle, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
