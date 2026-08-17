import 'dart:async';

import 'package:flutter/material.dart';

import 'browser_lifecycle.dart';

class SessionGuard extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final VoidCallback onTimeout;

  const SessionGuard({super.key, required this.child, required this.timeout, required this.onTimeout});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<BrowserLifecycleEvent>? _browserLifecycleSubscription;
  DateTime _ultimaAtividade = DateTime.now();
  DateTime? _suspensaEm;
  bool _encerrando = false;

  @override
  void initState() {
    super.initState();
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
    }
  }

  void _registrarAtividade() {
    if (_encerrando) return;
    _ultimaAtividade = DateTime.now();
    _suspensaEm = null;
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
