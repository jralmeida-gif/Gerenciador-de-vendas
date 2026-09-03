import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Edição das metas individuais mensais por produto.
class TelaMetasEditar extends StatefulWidget {
  const TelaMetasEditar({super.key});

  @override
  State<TelaMetasEditar> createState() => _TelaMetasEditarState();
}

class _TelaMetasEditarState extends State<TelaMetasEditar> {
  final Map<String, TextEditingController> _ctrls = {};
  final _busca = TextEditingController();
  bool _somenteComMeta = false;
  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
  static const _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  String get _mesRef => '${_mesSelecionado.year}-${_mesSelecionado.month.toString().padLeft(2, '0')}';
  String get _mesLabel => '${_nomesMeses[_mesSelecionado.month - 1]} / ${_mesSelecionado.year}';

  @override
  void initState() {
    super.initState();
    _sincronizarControles(context.read<AppState>());
  }

  void _sincronizarControles(AppState estado) {
    for (final p in estado.produtos) {
      if (_ctrls.containsKey(p.nome)) continue;
      final meta = estado.metaMensalDoProduto(p.nome, _mesRef);
      _ctrls[p.nome] = TextEditingController(
        text: meta > 0
            ? (p.ehQuantidade ? Fmt.inteiro(meta) : Fmt.decimal(meta))
            : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _busca.dispose();
    super.dispose();
  }

  Future<void> _trocarMes() async {
    var ano = _mesSelecionado.year;
    var mes = _mesSelecionado.month;
    final escolha = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, atualizar) => AlertDialog(
          title: const Text('Escolher mês da meta'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: mes,
                  decoration: const InputDecoration(labelText: 'Mês'),
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_nomesMeses[i]))),
                  onChanged: (v) { if (v != null) atualizar(() => mes = v); },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<int>(
                  initialValue: ano,
                  decoration: const InputDecoration(labelText: 'Ano'),
                  items: List.generate(11, (i) => DropdownMenuItem(value: DateTime.now().year - 5 + i, child: Text('${DateTime.now().year - 5 + i}'))),
                  onChanged: (v) { if (v != null) atualizar(() => ano = v); },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, DateTime(ano, mes)), child: const Text('Selecionar')),
          ],
        ),
      ),
    );
    if (escolha == null || !mounted) return;
    final estado = context.read<AppState>();
    _sincronizarControles(estado);
    setState(() {
      _mesSelecionado = DateTime(escolha.year, escolha.month);
      for (final p in estado.produtos) {
        final valor = estado.metaMensalDoProduto(p.nome, _mesRef);
        _ctrls[p.nome]!.text = valor > 0 ? (p.ehQuantidade ? Fmt.inteiro(valor) : Fmt.decimal(valor)) : '';
      }
    });
  }

  Future<void> _salvar() async {
    final estado = context.read<AppState>();
    final valores = <String, double>{};
    for (final e in _ctrls.entries) {
      final produto = estado.produtos.firstWhere((p) => p.nome == e.key);
      final metaAnterior = estado.metaMensalDoProduto(e.key, _mesRef);
      if (!produto.ativo && metaAnterior <= 0) continue;
      valores[e.key] = Fmt.parseNumero(e.value.text);
    }
    await estado.salvarMetasMensais(_mesRef, valores);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metas atualizadas.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    _sincronizarControles(estado);
    final q = _busca.text.trim().toLowerCase();

    var produtos = estado.produtos
        .where((p) => p.ativo || estado.metaMensalDoProduto(p.nome, _mesRef) > 0)
        .toList();
    if (q.isNotEmpty) {
      produtos = produtos
          .where((p) => p.nome.toLowerCase().contains(q))
          .toList();
    }
    if (_somenteComMeta) {
      produtos = produtos
          .where((p) => Fmt.parseNumero(_ctrls[p.nome]?.text ?? '') > 0)
          .toList();
    }

    final totalComMeta = _ctrls.values
        .where((c) => Fmt.parseNumero(c.text) > 0)
        .length;

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Metas do mês',
            subtitulo: 'Meta individual · $totalComMeta produto(s) com meta',
            mostrarVoltar: true,
            rodape: TextField(
              controller: _busca,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar produto',
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
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _trocarMes,
                  icon: const Icon(Icons.calendar_month_outlined, size: 17),
                  label: Text(_mesLabel),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Os valores abaixo são metas individuais diretas.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FilterChip(
                  label: const Text(
                    'Com meta',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: _somenteComMeta,
                  onSelected: (v) => setState(() => _somenteComMeta = v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.14),
                  checkmarkColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: produtos.isEmpty
                ? const EstadoVazio(
                    icone: Icons.flag_outlined,
                    titulo: 'Nenhum produto encontrado',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    itemCount: produtos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = produtos[i];
                      final ctrl = _ctrls[p.nome]!;
                      final meta = Fmt.parseNumero(ctrl.text);
                      final indiv = meta;
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: meta > 0
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : AppColors.divider,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.nome,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Etiqueta(
                                  texto: p.formato,
                                  cor: p.ehQuantidade
                                      ? AppColors.primaryLight
                                      : AppColors.accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: p.ehQuantidade
                                        ? null
                                        : [MoedaInputFormatter()],
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: p.ehQuantidade ? '0' : '0,00',
                                      prefixText: p.ehQuantidade
                                          ? null
                                          : 'R\$ ',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Individual',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        meta > 0
                                            ? Fmt.valorPorFormato(
                                                indiv,
                                                p.formato,
                                              )
                                            : '—',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: meta > 0
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save_outlined, size: 20),
            label: const RotuloBotao('SALVAR METAS'),
          ),
        ),
      ),
    );
  }
}
