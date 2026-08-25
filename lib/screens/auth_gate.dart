import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_client.dart';
import '../services/repositorio.dart';
import '../services/app_state.dart';
import '../services/session_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/comuns.dart';
import 'inicio.dart';

class AuthGate extends StatefulWidget {
  final Repositorio repo;
  const AuthGate({super.key, required this.repo});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _auth = AuthClient();
  AuthUser? _user;
  bool _loading = true;
  bool _setup = false;
  String? _resetToken;
  bool _revalidandoSessao = false;
  DateTime? _ultimaRevalidacao;
  Timer? _timerRevalidacaoSessao;
  bool _logoutEmAndamento = false;
  Future<void>? _limpezaPerfilPendente;
  int _cicloSessao = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerRevalidacaoSessao = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_revalidarSessaoAoRetomar()),
    );
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_revalidarSessaoAoRetomar());
    }
  }

  Future<void> _revalidarSessaoAoRetomar() async {
    if (!mounted || _loading || _user == null || _revalidandoSessao) return;
    final agora = DateTime.now();
    if (_ultimaRevalidacao != null &&
        agora.difference(_ultimaRevalidacao!) < const Duration(seconds: 15)) {
      return;
    }
    _revalidandoSessao = true;
    try {
      final resultado = await _auth.checkSession();
      if (!mounted || !resultado.reachable) return;
      _ultimaRevalidacao = DateTime.now();
      if (resultado.user != null) {
        final appState = context.read<AppState>();
        appState.definirUsuarioAutenticado(resultado.user);
        unawaited(appState.carregarCatalogoDaNuvem());
        if (resultado.user!.id != _user!.id ||
            resultado.user!.role != _user!.role ||
            resultado.user!.mustChangePassword != _user!.mustChangePassword) {
          setState(() => _user = resultado.user);
        }
        return;
      }
      final appState = context.read<AppState>();
      await appState.mudarPerfilLocal('guest');
      appState.definirUsuarioAutenticado(null);
      if (!mounted) return;
      setState(() => _user = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sua sessão foi encerrada. Entre novamente com a senha atualizada.',
          ),
        ),
      );
    } finally {
      _revalidandoSessao = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerRevalidacaoSessao?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final resetToken = Uri.base.queryParameters['reset_token'];
    if (resetToken != null && resetToken.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resetToken = resetToken;
          _loading = false;
        });
      }
      return;
    }
    final appState = context.read<AppState>();
    var user = await _auth.session();
    var setup = false;
    if (user != null) {
      await widget.repo.switchProfile(user.username);
      await widget.repo.registrarPerfilAutenticado(
        userId: user.id,
        username: user.username,
      );
      final ultimaAtividade = appState.ultimaAtividadeSessao;
      final expirouPorInatividade =
          ultimaAtividade != null &&
          DateTime.now().difference(ultimaAtividade) >=
              Duration(minutes: appState.idleTimeoutMinutes);
      if (expirouPorInatividade) {
        await appState.limparUltimaAtividadeSessao();
        await widget.repo.switchProfile('guest');
        appState.definirUsuarioAutenticado(null);
        unawaited(_auth.logout());
        user = null;
      } else if (mounted) {
        await appState.carregarDaNuvem();
        await appState.carregarCatalogoDaNuvem();
        unawaited(appState.criarBackupInterno());
      }
    } else {
      await appState.reconciliarLimpezaGlobalSemSessao();
      setup = await _auth.setupRequired();
    }
    if (!mounted) return;
    if (user != null) appState.definirUsuarioAutenticado(user);
    setState(() {
      _user = user;
      _setup = setup;
      _loading = false;
    });
  }

  Future<void> _loggedIn(AuthResult result) async {
    if (!result.ok || result.user == null) {
      _showError(result.error ?? 'Não foi possível entrar.');
      return;
    }
    final limpezaPendente = _limpezaPerfilPendente;
    if (limpezaPendente != null) await limpezaPendente;
    if (!mounted) return;
    _logoutEmAndamento = false;
    final appState = context.read<AppState>();
    await widget.repo.switchProfile(result.user!.username);
    await widget.repo.registrarPerfilAutenticado(
      userId: result.user!.id,
      username: result.user!.username,
    );
    if (mounted) {
      await appState.carregarDaNuvem();
      await appState.carregarCatalogoDaNuvem();
      unawaited(appState.criarBackupInterno());
    }
    if (!mounted) return;
    appState.definirUsuarioAutenticado(result.user);
    await appState.salvarUltimaAtividadeSessao(DateTime.now());
    setState(() {
      _cicloSessao++;
      _user = result.user;
    });
  }

  void _showError(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _senhaDefinitivaSalva() async {
    final atual = _user;
    if (atual == null || !mounted) return;
    setState(
      () => _user = AuthUser(
        id: atual.id,
        username: atual.username,
        role: atual.role,
        mustChangePassword: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final ctrl = TextEditingController(
      text: context.read<AppState>().nomeUsuario == 'Usuário'
          ? ''
          : context.read<AppState>().nomeUsuario,
    );
    final alias = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Como você gostaria de ser chamado?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome ou alias'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (alias != null && alias.isNotEmpty && mounted) {
      await context.read<AppState>().salvarNomeUsuario(alias);
    }
    if (!mounted) return;
    final recovery = TextEditingController(
      text: context.read<AppState>().recoveryEmail,
    );
    final recoveryEmail = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('E-mail de recuperação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cadastre um e-mail pessoal ou corporativo para receber o link caso você esqueça sua senha. Pode ser Gmail, Outlook ou outro provedor.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recovery,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail de recuperação',
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              final value = recovery.text.trim();
              if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('Salvar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cadastrar depois'),
          ),
        ],
      ),
    );
    recovery.dispose();
    if (recoveryEmail != null && recoveryEmail.isNotEmpty && mounted) {
      await context.read<AppState>().salvarRecoveryEmail(recoveryEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_resetToken != null) {
      return ResetPasswordView(
        auth: _auth,
        token: _resetToken!,
        onDone: () => setState(() => _resetToken = null),
      );
    }
    if (_user == null) {
      return LoginView(auth: _auth, setup: _setup, onLoggedIn: _loggedIn);
    }
    if (_user!.mustChangePassword) {
      return ChangePasswordView(auth: _auth, onDone: _senhaDefinitivaSalva);
    }
    Future<void> sair() async {
      if (_logoutEmAndamento) return;
      _logoutEmAndamento = true;
      final appState = context.read<AppState>();

      // A troca visual precisa acontecer antes de qualquer await. Assim, o
      // conteúdo autenticado não permanece visível enquanto a limpeza local
      // é executada.
      if (mounted) {
        appState.definirUsuarioAutenticado(null);
        setState(() {
          _cicloSessao++;
          _user = null;
        });
      }
      unawaited(appState.limparUltimaAtividadeSessao());

      // Inicia a limpeza do perfil local sem bloquear a troca visual para o login.
      // Um login novo aguarda essa operação para evitar misturar perfis locais.
      final limpezaLocal = appState.mudarPerfilLocal('guest');
      _limpezaPerfilPendente = limpezaLocal;
      unawaited(
        limpezaLocal.whenComplete(() {
          if (identical(_limpezaPerfilPendente, limpezaLocal)) {
            _limpezaPerfilPendente = null;
            _logoutEmAndamento = false;
          }
        }),
      );

      // A invalidação remota é uma operação de melhor esforço, com timeout.
      unawaited(_auth.logout());
    }

    return Selector<AppState, int>(
      selector: (_, state) => state.idleTimeoutMinutes,
      builder: (_, timeoutMinutes, __) => SessionGuard(
        key: ValueKey('session-$_cicloSessao-${_user!.id}'),
        timeout: Duration(minutes: timeoutMinutes),
        ultimaAtividadeInicial: context.read<AppState>().ultimaAtividadeSessao,
        onAtividade: context.read<AppState>().salvarUltimaAtividadeSessao,
        onTimeout: () => unawaited(sair()),
        child: TelaInicio(user: _user!, onLogout: () => unawaited(sair())),
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  final AuthClient auth;
  final bool setup;
  final Future<void> Function(AuthResult) onLoggedIn;
  const LoginView({
    super.key,
    required this.auth,
    required this.setup,
    required this.onLoggedIn,
  });
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
    final result = widget.setup
        ? await widget.auth.registerFirst(_username.text, _password.text)
        : await widget.auth.login(_username.text, _password.text);
    if (mounted) setState(() => _busy = false);
    await widget.onLoggedIn(result);
  }

  Future<void> _esqueciSenha() async {
    final username = TextEditingController(text: _username.text.trim());
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Esqueci minha senha'),
        content: TextField(
          controller: username,
          autofocus: username.text.isEmpty,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Usuário ou prefixo do e-mail',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, username.text.trim()),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
    username.dispose();
    if (resultado == null || resultado.isEmpty || !mounted) return;
    setState(() => _busy = true);
    final resposta = await widget.auth.requestPasswordReset(resultado);
    if (!mounted) return;
    setState(() => _busy = false);
    final detalhes = <String>[
      resposta.message,
      if (resposta.recipient != null) 'Destino: ${resposta.recipient}',
      if (resposta.deliveryStatus != null)
        'Status Mailjet: ${resposta.deliveryStatus}',
      if (resposta.deliveryReason != null) 'Motivo: ${resposta.deliveryReason}',
      if (resposta.accepted)
        'A aceitação pela Mailjet não garante que a mensagem já esteja na caixa de entrada. Verifique também o lixo eletrônico e aguarde alguns minutos.',
    ].join('\n\n');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          resposta.accepted ? 'Status do e-mail' : 'Não foi possível solicitar',
        ),
        content: Text(detalhes),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: widget.setup ? 'Configuração inicial' : 'Entrar no Gestor de Vendas',
    subtitle: widget.setup
        ? 'Cadastre o primeiro usuário. Ele será administrador automaticamente.'
        : 'Use seu usuário ou o e-mail cadastrado.',
    children: [
      TextField(
        controller: _username,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Usuário ou e-mail',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: 14),
      CampoSenha(
        controller: _password,
        labelText: widget.setup ? 'Senha inicial' : 'Senha',
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.setup ? 'Criar administrador' : 'Entrar'),
        ),
      ),
      if (!widget.setup) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _esqueciSenha,
          icon: const Icon(Icons.help_outline, size: 18),
          label: const Text('Esqueci minha senha'),
        ),
      ],
    ],
  );
}

class ResetPasswordView extends StatefulWidget {
  final AuthClient auth;
  final String token;
  final VoidCallback onDone;
  const ResetPasswordView({
    super.key,
    required this.auth,
    required this.token,
    required this.onDone,
  });
  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (_newPassword.text.length < 8 ||
        _newPassword.text.length > 128 ||
        _newPassword.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A nova senha deve ter entre 8 e 128 caracteres e coincidir nos dois campos.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    final error = await widget.auth.resetPassword(
      widget.token,
      _newPassword.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Senha redefinida'),
        content: const Text(
          'Sua senha foi alterada. Entre no aplicativo com a nova senha.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ir para o login'),
          ),
        ],
      ),
    );
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Redefinir senha',
    subtitle: 'Crie uma nova senha para acessar o Gestor de Vendas.',
    children: [
      CampoSenha(controller: _newPassword, labelText: 'Nova senha'),
      const SizedBox(height: 14),
      CampoSenha(controller: _confirm, labelText: 'Confirme a nova senha'),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Salvando...' : 'Redefinir senha'),
        ),
      ),
    ],
  );
}

class ChangePasswordView extends StatefulWidget {
  final AuthClient auth;
  final VoidCallback onDone;
  const ChangePasswordView({
    super.key,
    required this.auth,
    required this.onDone,
  });
  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  Future<void> _submit() async {
    if (_newPassword.text.length < 8 || _newPassword.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A nova senha deve ter 8 caracteres e coincidir nos dois campos.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    final error = await widget.auth.changePassword(
      _current.text,
      _newPassword.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Crie sua senha definitiva',
    subtitle:
        'Por segurança, a senha temporária precisa ser trocada antes do primeiro acesso.',
    children: [
      CampoSenha(controller: _current, labelText: 'Senha temporária'),
      const SizedBox(height: 14),
      CampoSenha(controller: _newPassword, labelText: 'Nova senha'),
      const SizedBox(height: 14),
      CampoSenha(controller: _confirm, labelText: 'Confirme a nova senha'),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Salvando...' : 'Salvar nova senha'),
        ),
      ),
    ],
  );
}

class _AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });
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
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
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
