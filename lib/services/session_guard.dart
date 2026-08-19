import 'dart:async';

import 'package:flutter/material.dart';

import 'browser_lifecycle.dart';

class SessionGuard extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final VoidCallback onTimeout;
  final DateTime? ultimaAtividadeInicial;
  final Future<void> Function(DateTime)? onAtividade;

  const SessionGuard({
    super.key,
    required this.child,
    required this.timeout,
    required this.onTimeout,
    this.ultimaAtividadeInicial,
    this.onAtividade,
  });

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<BrowserLifecycleEvent>? _browserLifecycleSubscription;
  late DateTime _ultimaAtividade;
  DateTime? _ultimaAtividadePersistida;
  DateTime? _suspensaEm;
  bool _encerrando = false;

  @override
  void initState() {
    super.initState();
    // Cada montagem representa uma sessão nova. O reset explícito evita que
    // qualquer estado de uma instância anterior impeça o segundo ciclo.
    _encerrando = false;
    final agora = DateTime.now();
    final inicial = widget.ultimaAtividadeInicial;
    _ultimaAtividade = inicial != null && !inicial.isAfter(agora) ? inicial : agora;
    _ultimaAtividadePersistida = inicial;
    _suspensaEm = null;
    if (inicial == null) unawaited(widget.onAtividade?.call(agora));
    WidgetsBinding.instance.addObserver(this);
    _browserLifecycleSubscription = BrowserLifecycle.events.listen(_onBrowserLifecycle);
    _iniciarMonitor();
  }

  @override
  void didUpdateWidget(covariant SessionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeout != widget.timeout) _verificar();
  }

  void _iniciarMonitor() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _verificar());
  }

  void _onBrowserLifecycle(BrowserLifecycleEvent event) {
    if (_encerrando) return;
    switch (event) {
      case BrowserLifecycleEvent.hidden:
      case BrowserLifecycleEvent.blurred:
      case BrowserLifecycleEvent.pageHidden:
        _suspensaEm ??= DateTime.now();
        _verificar();
        break;
      case BrowserLifecycleEvent.visible:
      case BrowserLifecycleEvent.focused:
      case BrowserLifecycleEvent.pageShown:
        _verificar();
        _suspensaEm = null;
        break;
      case BrowserLifecycleEvent.activity:
        _registrarAtividade();
        break;
    }
  }

  void _registrarAtividade() {
    if (_encerrando) return;
    final agora = DateTime.now();
    _ultimaAtividade = agora;
    _suspensaEm = null;
    final ultimaPersistida = _ultimaAtividadePersistida;
    if (ultimaPersistida == null || agora.difference(ultimaPersistida) >= const Duration(seconds: 10)) {
      _ultimaAtividadePersistida = agora;
      unawaited(widget.onAtividade?.call(agora));
    }
  }

  void _verificar() {
    if (_encerrando) return;
    final agora = DateTime.now();
    if (agora.difference(_ultimaAtividade) >= widget.timeout) {
      _expirar();
    }
  }

  void _expirar() {
    if (_encerrando) return;
    _encerrando = true;
    _timer?.cancel();
    widget.onTimeout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _suspensaEm ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final inicioSuspensao = _suspensaEm;
      if (inicioSuspensao != null && DateTime.now().difference(inicioSuspensao) >= widget.timeout) {
        _expirar();
      } else {
        _verificar();
      }
      _suspensaEm = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _browserLifecycleSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registrarAtividade(),
      onPointerMove: (_) => _registrarAtividade(),
      onPointerSignal: (_) => _registrarAtividade(),
      child: widget.child,
    );
  }
}
