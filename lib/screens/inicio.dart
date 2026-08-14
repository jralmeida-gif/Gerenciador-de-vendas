import 'package:flutter/material.dart';

import '../services/auth_client.dart';
import '../theme/app_theme.dart';
import 'dashboard.dart';
import 'portabilidade_lista.dart';
import 'prospeccao_lista.dart';
import 'relatorios.dart';
import 'vendas_lista.dart';

/// Casca principal com a navegação inferior de 5 abas.
class TelaInicio extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onLogout;
  const TelaInicio({super.key, required this.user, required this.onLogout});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _indice = 0;
  late final List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    _paginas = [
      TelaDashboard(user: widget.user, onNavigate: _selecionarAba),
      const TelaVendasLista(),
      const TelaPortabilidadeLista(),
      const TelaProspeccaoLista(),
      const TelaRelatorios(),
    ];
  }

  void _selecionarAba(int indice) {
    if (!mounted) return;
    setState(() => _indice = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _paginas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: 23,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            child: NavigationBar(
              height: 64,
              selectedIndex: _indice,
              onDestinationSelected: (i) => setState(() => _indice = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: 'Vendas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: 'Portab.',
                ),
                NavigationDestination(
                  icon: Icon(Icons.phone_in_talk_outlined),
                  selectedIcon: Icon(Icons.phone_in_talk),
                  label: 'Prospec.',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insert_chart_outlined),
                  selectedIcon: Icon(Icons.insert_chart),
                  label: 'Relatórios',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
