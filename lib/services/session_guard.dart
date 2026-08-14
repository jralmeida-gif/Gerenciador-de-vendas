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

class _SessionGuardState extends State<SessionGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reiniciar();
  }

  @override
  void didUpdateWidget(covariant SessionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeout != widget.timeout) _reiniciar();
  }

  void _reiniciar() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
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
