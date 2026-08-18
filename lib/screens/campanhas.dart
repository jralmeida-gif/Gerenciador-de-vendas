import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Campanhas (Base Campanhas da planilha): nome, período e metas por produto.
class TelaCampanhas extends StatelessWidget {
  const TelaCampanhas({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final todas = [...estado.campanhas]
      ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
    final ativas = todas.where((c) => c.ativa).toList();
    final outras = todas.where((c) => !c.ativa).toList();

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Campanhas',
            subtitulo: '${ativas.length} ativa(s) · ${todas.length} no total',
            mostrarVoltar: true,
          ),
          Expanded(
            child: todas.isEmpty
                ? EstadoVazio(
                    icone: Icons.campaign_outlined,
                    titulo: 'Nenhuma campanha cadastrada',
                    mensagem:
                        'Crie campanhas com período e metas por produto para acompanhar o progresso.',
                    acao: ElevatedButton.icon(
                      onPressed: () => _abrirForm(context, null),
                      icon: const Icon(Icons.add, size: 20),
                      label: const RotuloBotao('CRIAR CAMPANHA'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    children: [
                      if (ativas.isNotEmpty) ...[
                        const _Titulo('Em andamento'),
                        ...ativas.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CartaoCampanha(campanha: c, ativa: true),
                          ),
                        ),
                      ],
                      if (outras.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const _Titulo('Encerradas / futuras'),
                        ...outras.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CartaoCampanha(campanha: c, ativa: false),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: todas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirForm(context, null),
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

  static void _abrirForm(BuildContext context, Campanha? c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaCampanhaForm(campanha: c)),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4, left: 2),
    child: Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

class _CartaoCampanha extends StatelessWidget {
  final Campanha campanha;
  final bool ativa;
  const _CartaoCampanha({required this.campanha, required this.ativa});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final itens = campanha.metasPorProduto.entries.map((e) {
      final real = estado.realizadoProduto(
        e.key,
        campanha.dataInicio,
        campanha.dataFim,
      );
      return ItemCampanha(
        produto: e.key,
        meta: e.value,
        realizado: real,
        formato: estado.formatoDoProduto(e.key),
      );
    }).toList()..sort((a, b) => a.perc.compareTo(b.perc));

    final percGeral = itens.isEmpty
        ? 0.0
        : itens.fold<double>(0, (s, i) => s + i.perc.clamp(0, 2)) /
              itens.length;

    final hoje = DateTime.now();
    final diasRestantes = campanha.dataFim
        .difference(DateTime(hoje.year, hoje.month, hoje.day))
        .inDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ativa
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (ativa ? AppColors.accent : AppColors.textSecondary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  size: 21,
                  color: ativa ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campanha.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${Fmt.data(campanha.dataInicio)} a ${Fmt.data(campanha.dataFim)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onSelected: (v) async {
                  if (v == 'editar') {
                    TelaCampanhas._abrirForm(context, campanha);
                  } else if (v == 'excluir') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir campanha'),
                        content: Text('Remover "${campanha.nome}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<AppState>().excluirCampanha(
                        campanha.id,
                      );
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: BarraProgresso(valor: percGeral)),
              const SizedBox(width: 10),
              Text(
                Fmt.percentual(percGeral),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.semaforo(percGeral),
                ),
              ),
            ],
          ),
          if (ativa) ...[
            const SizedBox(height: 8),
            Etiqueta(
              texto: diasRestantes <= 0
                  ? 'Último dia'
                  : 'Faltam $diasRestantes dia(s)',
              cor: diasRestantes <= 3 ? AppColors.danger : AppColors.primary,
              icone: Icons.timer_outlined,
            ),
          ],
          const SizedBox(height: 12),
          ...itens.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          i.produto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${Fmt.valorPorFormato(i.realizado, i.formato)} / ${Fmt.valorPorFormato(i.meta, i.formato)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  BarraProgresso(valor: i.perc, altura: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class TelaCampanhaForm extends StatefulWidget {
  final Campanha? campanha;
  const TelaCampanhaForm({super.key, this.campanha});

  @override
  State<TelaCampanhaForm> createState() => _TelaCampanhaFormState();
}

class _TelaCampanhaFormState extends State<TelaCampanhaForm> {
  final _nome = TextEditingController();
  DateTime _inicio = DateTime.now();
  DateTime _fim = DateTime.now().add(const Duration(days: 30));
  final Map<String, TextEditingController> _metas = {};

  bool get _editando => widget.campanha != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campanha;
    if (c != null) {
      _nome.text = c.nome;
      _inicio = c.dataInicio;
      _fim = c.dataFim;
    }
    final estado = context.read<AppState>();
    for (final p in _editando ? estado.produtos : estado.produtosAtivos) {
      final v = c?.metasPorProduto[p.nome] ?? 0;
      _metas[p.nome] = TextEditingController(
        text: v > 0 ? (p.ehQuantidade ? Fmt.inteiro(v) : Fmt.decimal(v)) : '',
      );
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    for (final c in _metas.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherData(bool inicio) async {
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fim,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d == null) return;
    setState(() {
      if (inicio) {
        _inicio = d;
        if (_fim.isBefore(_inicio)) _fim = _inicio;
      } else {
        _fim = d;
      }
    });
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().length < 3) {
      _aviso('Informe o nome da campanha.');
      return;
    }
    final metas = <String, double>{};
    for (final e in _metas.entries) {
      final v = Fmt.parseNumero(e.value.text);
      if (v > 0) metas[e.key] = v;
    }
    if (metas.isEmpty) {
      _aviso('Defina a meta de pelo menos um produto.');
      return;
    }

    final estado = context.read<AppState>();
    final c = Campanha(
      id: widget.campanha?.id ?? estado.novoId(),
      nome: _nome.text.trim(),
      dataInicio: _inicio,
      dataFim: _fim,
      metasPorProduto: metas,
    );
    await estado.salvarCampanha(c);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _aviso(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final selecionados = _metas.values
        .where((c) => Fmt.parseNumero(c.text) > 0)
        .length;
    final produtosExibidos = _editando ? estado.produtos : estado.produtosAtivos;

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: _editando ? 'Editar campanha' : 'Nova campanha',
            subtitulo: '$selecionados produto(s) com meta definida',
            mostrarVoltar: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                CartaoSecao(
                  titulo: 'Dados da campanha',
                  child: Column(
                    children: [
                      CampoTexto(
                        rotulo: 'Nome',
                        controller: _nome,
                        dica: 'Ex.: Campanha Consignado Setembro',
                        capitalizacao: TextCapitalization.words,
                        prefixo: const Icon(Icons.campaign_outlined, size: 20),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Data(
                              rotulo: 'Início',
                              valor: Fmt.data(_inicio),
                              onTap: () => _escolherData(true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Data(
                              rotulo: 'Fim',
                              valor: Fmt.data(_fim),
                              onTap: () => _escolherData(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CartaoSecao(
                  titulo: 'Metas por produto',
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Preencha apenas os produtos que fazem parte da campanha.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      ...produtosExibidos.map((p) {
                        final ctrl = _metas[p.nome]!;
                        final ativo = Fmt.parseNumero(ctrl.text) > 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  p.nome,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: ativo
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: ativo
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 118,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  inputFormatters: p.ehQuantidade
                                      ? null
                                      : [MoedaInputFormatter()],
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: p.ehQuantidade ? 'qtd' : '0,00',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const RotuloBotao('CANCELAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const RotuloBotao('SALVAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Data extends StatelessWidget {
  final String rotulo;
  final String valor;
  final VoidCallback onTap;
  const _Data({required this.rotulo, required this.valor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
