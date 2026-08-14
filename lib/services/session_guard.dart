import 'dart:async';

import 'package:flutter/material.dart';

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
  DateTime _ultimaAtividade = DateTime.now();
  bool _encerrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reiniciar();
  }

  @override
  void didUpdateWidget(covariant SessionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeout != widget.timeout) _reiniciar();
  }

  void _reiniciar() {
    _ultimaAtividade = DateTime.now();
    _timer?.cancel();
    _timer = Timer(widget.timeout, _expirar);
  }

  void _expirar() {
    if (_encerrando) return;
    _encerrando = true;
    widget.onTimeout();
  }

  void _verificarAoRetornar() {
    if (DateTime.now().difference(_ultimaAtividade) >= widget.timeout) {
      _expirar();
    } else {
      _reiniciar();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verificarAoRetornar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _reiniciar(),
      onPointerMove: (_) => _reiniciar(),
      onPointerSignal: (_) => _reiniciar(),
      child: MouseRegion(onHover: (_) => _reiniciar(), child: widget.child),
    );
  }
}
