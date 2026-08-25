import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/auth_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

class TelaAtividadeAdmin extends StatefulWidget {
  const TelaAtividadeAdmin({super.key});

  @override
  State<TelaAtividadeAdmin> createState() => _TelaAtividadeAdminState();
}

class _TelaAtividadeAdminState extends State<TelaAtividadeAdmin> {
  final _auth = AuthClient();
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final activities = await _auth.listAdminActivities(limit: 200);
      if (!mounted) return;
      setState(() { _activities = activities; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _label(String value) {
    switch (value) {
      case 'login':
        return 'Entrou no aplicativo';
      case 'logout':
        return 'Saiu do aplicativo';
      case 'dados_sincronizados':
        return 'Sincronizou os dados';
      case 'venda_criada':
        return 'Cadastrou venda';
      case 'venda_alterada':
        return 'Alterou venda';
      case 'venda_excluida':
        return 'Excluiu venda';
      case 'portabilidade_criada':
        return 'Cadastrou portabilidade';
      case 'portabilidade_alterada':
        return 'Alterou portabilidade';
      case 'portabilidade_excluida':
        return 'Excluiu portabilidade';
      case 'prospeccao_criada':
        return 'Cadastrou prospecção';
      case 'prospeccao_alterada':
        return 'Alterou prospecção';
      case 'prospeccao_excluida':
        return 'Excluiu prospecção';
      case 'cliente_criado':
        return 'Cadastrou ficha de cliente';
      case 'cliente_alterado':
        return 'Alterou ficha de cliente';
      case 'cliente_excluido':
        return 'Excluiu ficha de cliente';
      case 'usuario_criado':
        return 'Cadastrou um usuário';
      case 'usuario_alterado':
        return 'Alterou um usuário';
      case 'usuario_excluido':
        return 'Excluiu um usuário';
      case 'catalogo_criado':
        return 'Cadastrou item no catálogo';
      case 'catalogo_atualizado':
        return 'Atualizou item do catálogo';
      case 'catalogo_renomeado':
        return 'Renomeou item do catálogo';
      case 'catalogo_excluido':
        return 'Desativou item do catálogo';
      case 'limpeza_global':
        return 'Executou limpeza global';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  IconData _icon(String value) {
    if (value == 'login') return Icons.login_outlined;
    if (value == 'logout') return Icons.logout_outlined;
    if (value == 'dados_sincronizados') return Icons.sync_outlined;
    if (value.startsWith('venda_')) return Icons.point_of_sale_outlined;
    if (value.startsWith('portabilidade_')) return Icons.swap_horiz_outlined;
    if (value.startsWith('prospeccao_')) return Icons.person_search_outlined;
    if (value.startsWith('cliente_')) return Icons.person_outline;
    if (value.startsWith('usuario_')) return Icons.manage_accounts_outlined;
    if (value.startsWith('catalogo_')) return Icons.inventory_2_outlined;
    if (value == 'limpeza_global') return Icons.delete_forever_outlined;
    return Icons.history_outlined;
  }

  Color _color(String value) {
    if (value == 'limpeza_global' || value.endsWith('_excluido')) {
      return AppColors.danger;
    }
    if (value.endsWith('_criada') || value.endsWith('_criado') || value == 'login') {
      return AppColors.success;
    }
    return AppColors.primary;
  }

  Widget _activityCard(Map<String, dynamic> item) {
    final activity = item['activity']?.toString() ?? '';
    final username = item['actor_username']?.toString() ?? 'Usuário';
    final role = item['actor_role']?.toString() == 'admin'
        ? 'Administrador'
        : 'Usuário comum';
    final parsed = DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal();
    final date = parsed == null ? 'Data não disponível' : Fmt.dataHora(parsed);
    final result = item['result']?.toString() ?? 'success';
    final quantity = int.tryParse(item['details']?.toString().replaceFirst('quantidade=', '') ?? '');
    final quantityLabel = quantity == null
        ? ''
        : ' · $quantity ${quantity == 1 ? 'registro' : 'registros'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _color(activity).withValues(alpha: 0.10),
          child: Icon(_icon(activity), color: _color(activity), size: 20),
        ),
        title: Text(
          '${_label(activity)}$quantityLabel',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$username · $role\n$date'),
        isThreeLine: true,
        trailing: result == 'success'
            ? const Icon(Icons.check_circle_outline, color: AppColors.success)
            : const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppState>().authUser?.isAdmin == true;
    if (!isAdmin) {
      return Scaffold(
        body: Column(
          children: [
            const HeaderCurvo(
              titulo: 'Acesso restrito',
              subtitulo: 'Esta página é exclusiva para administradores',
              mostrarVoltar: true,
              mostrarAcoesGlobais: false,
            ),
            const Expanded(
              child: EstadoVazio(
                icone: Icons.lock_outline,
                titulo: 'Acesso restrito',
                mensagem: 'Entre com uma conta administradora para consultar este histórico.',
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(
            titulo: 'Acessos e atividades',
            subtitulo: 'Histórico administrativo sem dados de clientes',
            mostrarVoltar: true,
            mostrarAcoesGlobais: false,
            ajudaContextualTitulo: 'Acessos e atividades',
            ajudaContextualTexto:
                'Mostra quem acessou o sistema e quais operações técnicas e operacionais foram realizadas.',
            ajudaContextualComoUsar:
                'Use o histórico para acompanhar acessos e o volume de operações realizadas no aplicativo.',
            ajudaContextualAtencao:
                'O histórico não exibe CPF, nome, telefone, produto, valor ou conteúdo de cliente.',
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'São exibidos até 200 registros recentes. O histórico registra a atividade técnica ou operacional, o perfil que a executou, a quantidade afetada e o horário.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_error != null)
                          EstadoVazio(
                            icone: Icons.cloud_off_outlined,
                            titulo: 'Não foi possível carregar o histórico',
                            mensagem: _error,
                            acao: OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('TENTAR NOVAMENTE'),
                            ),
                          )
                        else if (_activities.isEmpty)
                          const EstadoVazio(
                            icone: Icons.history_outlined,
                            titulo: 'Nenhuma atividade registrada',
                            mensagem: 'Os próximos acessos e operações aparecerão aqui.',
                          )
                        else
                          ..._activities.map(_activityCard),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
