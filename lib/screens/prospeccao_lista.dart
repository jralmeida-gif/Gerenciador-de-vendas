import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/whatsapp.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';
import 'prospeccao_form.dart';
import 'venda_form.dart';

/// Lista de prospecções com alerta de follow-up (data de retorno).
class TelaProspeccaoLista extends StatefulWidget {
  const TelaProspeccaoLista({super.key});

  @override
  State<TelaProspeccaoLista> createState() => _TelaProspeccaoListaState();
}

class _TelaProspeccaoListaState extends State<TelaProspeccaoLista>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _busca = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _busca.dispose();
    super.dispose();
  }

  DateTime get _hoje {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _vencida(Prospeccao p) =>
      !p.concluida &&
      p.dataRetorno != null &&
      !DateTime(
        p.dataRetorno!.year,
        p.dataRetorno!.month,
        p.dataRetorno!.day,
      ).isAfter(_hoje);

  List<Prospeccao> _filtrar(List<Prospeccao> base) {
    final q = _busca.text.trim().toLowerCase();
    if (q.isEmpty) return base;
    final digitos = Fmt.somenteDigitos(q);
    return base.where((p) {
      final nome = p.nome.toLowerCase().contains(q);
      final cpf = digitos.isNotEmpty && p.cpf.contains(digitos);
      final prod = p.produto.toLowerCase().contains(q);
      return nome || cpf || prod;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final todas = estado.prospeccoes;

    final retornos = todas.where(_vencida).toList()
      ..sort((a, b) => a.dataRetorno!.compareTo(b.dataRetorno!));
    final emAberto = todas.where((p) => !p.concluida && !_vencida(p)).toList();
    final concluidas = todas.where((p) => p.concluida).toList();

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Prospecção',
            subtitulo: '${todas.length} registro(s) na base',
            rodape: Column(
              children: [
                TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, CPF ou produto',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _busca.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _busca.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Retornos (${retornos.length})'),
                Tab(text: 'Em aberto (${emAberto.length})'),
                Tab(text: 'Concluídas (${concluidas.length})'),
              ],
            ),
          ),
          if (retornos.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.warning.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${retornos.length} cliente(s) aguardando retorno hoje ou atrasado(s)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A6116),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _lista(_filtrar(retornos), vazio: 'Nenhum retorno pendente'),
                _lista(
                  _filtrar(emAberto),
                  vazio: 'Nenhuma prospecção em aberto',
                ),
                _lista(
                  _filtrar(concluidas),
                  vazio: 'Nenhuma prospecção concluída',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaProspeccaoForm()),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _lista(List<Prospeccao> itens, {required String vazio}) {
    if (itens.isEmpty) {
      return EstadoVazio(
        icone: Icons.phone_in_talk_outlined,
        titulo: vazio,
        mensagem: 'Registre clientes com interesse e agende o retorno.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CartaoProsp(
        prosp: itens[i],
        atrasada: _vencida(itens[i]),
        onAcoes: () => _acoes(itens[i]),
      ),
    );
  }

  Future<void> _acoes(Prospeccao p) async {
    final estado = context.read<AppState>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.produto} · ${Fmt.cpf(p.cpf)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
              title: const Text('Enviar mensagem pelo WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await WhatsApp.abrir(telefone: p.telefone, mensagem: WhatsApp.saudacao(p.nome, complemento: 'Estou retornando o contato sobre ${p.produto}.'));
                if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone inválido para abrir o WhatsApp.')));
              },
            ),
            if (!p.concluida)
              ListTile(
                leading: const Icon(
                  Icons.point_of_sale,
                  color: AppColors.success,
                ),
                title: const Text(
                  'Converter em venda',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Abre o lançamento com os dados do cliente',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaVendaForm(
                        cpfInicial: p.cpf,
                        nomeInicial: p.nome,
                        telefoneInicial: p.telefone,
                        produtoInicial: p.produto,
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(
                p.concluida
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                p.concluida ? 'Reabrir prospecção' : 'Marcar como concluída',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await estado.salvarProspeccao(
                  p.copyWith(concluida: !p.concluida),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.textSecondary,
              ),
              title: const Text(
                'Editar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TelaProspeccaoForm(prospeccao: p),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text(
                'Excluir',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await _confirmarExclusao(p.nome);
                if (ok == true) await estado.excluirProspeccao(p.id);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmarExclusao(String nome) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir prospecção'),
      content: Text('Remover o registro de $nome?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

class _CartaoProsp extends StatelessWidget {
  final Prospeccao prosp;
  final bool atrasada;
  final VoidCallback onAcoes;

  const _CartaoProsp({
    required this.prosp,
    required this.atrasada,
    required this.onAcoes,
  });

  @override
  Widget build(BuildContext context) {
    final cor = prosp.concluida
        ? AppColors.success
        : atrasada
        ? AppColors.warning
        : AppColors.primary;

    return InkWell(
      onTap: onAcoes,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    prosp.concluida
                        ? Icons.check_rounded
                        : Icons.phone_in_talk_outlined,
                    color: cor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prosp.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prosp.produto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Etiqueta(
                  texto: 'Contato ${Fmt.dataCurta(prosp.data)}',
                  cor: AppColors.textSecondary,
                  icone: Icons.event_available_outlined,
                ),
                if (prosp.dataRetorno != null)
                  Etiqueta(
                    texto: 'Retorno ${Fmt.data(prosp.dataRetorno!)}',
                    cor: atrasada ? AppColors.warning : AppColors.primary,
                    icone: Icons.event_repeat_outlined,
                  ),
                if (prosp.telefone.isNotEmpty)
                  Etiqueta(
                    texto: Fmt.telefone(prosp.telefone),
                    cor: AppColors.primaryLight,
                    icone: Icons.phone_outlined,
                  ),
              ],
            ),
            if (prosp.observacao.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  prosp.observacao,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
