import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_client.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'ajuda.dart';
import 'dashboard.dart';
import 'agenda.dart';
import 'configuracoes.dart';
import 'portabilidade_lista.dart';
import 'prospeccao_lista.dart';
import 'relatorios.dart';
import 'vendas_lista.dart';

/// Casca principal com a navegação inferior de 5 abas.
class _NavItem extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.index, required this.label, required this.icon, required this.selectedIcon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                  child: Icon(selected ? selectedIcon : icon, size: 23, color: color),
                ),
                const SizedBox(height: 1),
                Text(label, style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TelaInicio extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onLogout;
  const TelaInicio({super.key, required this.user, required this.onLogout});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _indice = 0;
  Widget? _paginaGlobal;
  late final List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().configurarNavegacaoGlobal(
      agenda: () => _abrirGlobal(const TelaAgenda()),
      configuracoes: () => _abrirGlobal(TelaConfiguracoes(user: widget.user, onLogout: widget.onLogout)),
      ajuda: () => _abrirGlobal(const TelaAjuda()),
      voltar: _fecharGlobal,
      relatorio: _abrirGlobal,
    );
    _paginas = [
      TelaDashboard(
        user: widget.user,
        onNavigate: _selecionarAba,
        onLogout: widget.onLogout,
        onAgenda: () => _abrirGlobal(const TelaAgenda()),
        onConfig: () => _abrirGlobal(TelaConfiguracoes(user: widget.user, onLogout: widget.onLogout)),
      ),
      const TelaVendasLista(),
      const TelaPortabilidadeLista(),
      const TelaProspeccaoLista(),
      const TelaRelatorios(),
    ];
  }

  void _selecionarAba(int indice) {
    if (!mounted) return;
    setState(() {
      _indice = indice;
      _paginaGlobal = null;
    });
  }

  void _abrirGlobal(Widget pagina) {
    if (!mounted) return;
    setState(() => _paginaGlobal = pagina);
  }

  void _fecharGlobal() {
    if (!mounted) return;
    setState(() => _paginaGlobal = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginaGlobal ?? IndexedStack(index: _indice, children: _paginas),
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
          child:           SizedBox(
            height: 68,
            child: Row(
              children: [
                _NavItem(index: 0, label: 'Início', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, selected: _indice == 0, onTap: () => _selecionarAba(0)),
                _NavItem(index: 1, label: 'Vendas', icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale, selected: _indice == 1, onTap: () => _selecionarAba(1)),
                _NavItem(index: 2, label: 'Portab.', icon: Icons.swap_horiz_outlined, selectedIcon: Icons.swap_horiz, selected: _indice == 2, onTap: () => _selecionarAba(2)),
                _NavItem(index: 3, label: 'Prospec.', icon: Icons.phone_in_talk_outlined, selectedIcon: Icons.phone_in_talk, selected: _indice == 3, onTap: () => _selecionarAba(3)),
                _NavItem(index: 4, label: 'Relatórios', icon: Icons.insert_chart_outlined, selectedIcon: Icons.insert_chart, selected: _indice == 4, onTap: () => _selecionarAba(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
