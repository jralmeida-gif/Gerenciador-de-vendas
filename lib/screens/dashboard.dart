
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_client.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';
import 'campanhas.dart';
import 'metas_editar.dart';
import 'venda_form.dart';

class TelaDashboard extends StatelessWidget {
  final AuthUser user;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onLogout;
  final VoidCallback? onAgenda;
  final VoidCallback? onConfig;

  const TelaDashboard({super.key, required this.user, this.onNavigate, this.onLogout, this.onAgenda, this.onConfig});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final resumo = estado.resumo();
    final campanhas = estado.progressoCampanhas();
    final comMeta = resumo.linhas.where((l) => !l.semMeta).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: HeaderCurvo(
                  titulo: 'Início',
                  mostrarVoltar: false,
                  mostrarAcoesGlobais: true,
                ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _CartaoMetaMes(resumo: resumo),
                  const SizedBox(height: 12),
                  _PainelDesempenho(linhas: comMeta),
                  const SizedBox(height: 12),
                  _LinhaKpis(resumo: resumo, onNavigate: onNavigate),
                  if (campanhas.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _CartaoCampanhas(campanhas: campanhas),
                  ],
                  const SizedBox(height: 12),
                  _ListaProdutos(linhas: comMeta, todas: resumo.linhas),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaVendaForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova venda',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CartaoMetaMes extends StatelessWidget {
  final ResumoDashboard resumo;
  const _CartaoMetaMes({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final semMetas = resumo.produtosComMeta == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meta do mês',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.mesAno(hoje),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _MiniInfo(
                        icone: Icons.check_circle_outline,
                        cor: AppColors.success,
                        texto:
                            '${resumo.produtosAtingidos} de ${resumo.produtosComMeta} produtos na meta',
                      ),
                      const SizedBox(height: 8),
                      _MiniInfo(
                        icone: Icons.event_available_outlined,
                        cor: AppColors.primary,
                        texto: '${resumo.diasUteis} dias úteis restantes',
                      ),
                      const SizedBox(height: 8),
                      _MiniInfo(
                        icone: Icons.receipt_long_outlined,
                        cor: AppColors.accent,
                        texto: '${resumo.qtdVendasMes} vendas no mês',
                      ),
                    ],
                  ),
                ),
                AnelProgresso(
                  valor: resumo.percGeral,
                  tamanho: 118,
                  legenda: 'atingido',
                ),
              ],
            ),
            if (semMetas) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nenhuma meta cadastrada ainda.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TelaMetasEditar(),
                      ),
                    ),
                    child: const Text('Cadastrar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String texto;
  const _MiniInfo({
    required this.icone,
    required this.cor,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: cor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PainelDesempenho extends StatelessWidget {
  final List<LinhaMeta> linhas;
  const _PainelDesempenho({required this.linhas});

  @override
  Widget build(BuildContext context) {
    if (linhas.isEmpty) return const SizedBox.shrink();
    final meta = linhas.fold<double>(0, (s, l) => s + l.metaIndividual);
    final realizado = linhas.fold<double>(0, (s, l) => s + l.realizadoMes);
    final gap = linhas.fold<double>(0, (s, l) => s + (l.gap > 0 ? l.gap : 0));
    final ritmoAtual = linhas.fold<double>(0, (s, l) => s + l.ritmoAtual);
    final ritmoNecessario = linhas.fold<double>(0, (s, l) => s + l.metaDia);
    final projecao = linhas.fold<double>(0, (s, l) => s + l.projecaoMes);
    final eficiencia = meta > 0 ? (realizado / meta) : 0.0;
    final tendencia = ritmoAtual >= ritmoNecessario;
    final formato = linhas.first.formato;

    return CartaoSecao(
      titulo: 'Painel de desempenho · GAP e ritmo diário',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _IndicadorDesempenho(rotulo: 'Realizado', valor: Fmt.valorPorFormato(realizado, formato), cor: AppColors.primary)),
              Expanded(child: _IndicadorDesempenho(rotulo: 'GAP', valor: gap == 0 ? 'Meta batida' : Fmt.valorPorFormato(gap, formato), cor: gap == 0 ? AppColors.success : AppColors.danger)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _IndicadorDesempenho(rotulo: 'Ritmo atual/dia', valor: Fmt.valorPorFormato(ritmoAtual, formato), cor: AppColors.primary)),
              Expanded(child: _IndicadorDesempenho(rotulo: 'Necessário/dia', valor: Fmt.valorPorFormato(ritmoNecessario, formato), cor: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (tendencia ? AppColors.success : AppColors.warning).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(tendencia ? Icons.trending_up : Icons.warning_amber_outlined, color: tendencia ? AppColors.success : AppColors.warning, size: 22),
                const SizedBox(width: 9),
                Expanded(child: Text(tendencia ? 'O ritmo atual é suficiente para alcançar a meta.' : 'É necessário acelerar o ritmo diário para alcançar a meta.', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Eficiência no período: ${(eficiencia * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
              Text('Projeção: ${Fmt.valorPorFormato(projecao, formato)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndicadorDesempenho extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color cor;
  const _IndicadorDesempenho({required this.rotulo, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(rotulo, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      const SizedBox(height: 3),
      Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cor)),
    ]),
  );
}

class _LinhaKpis extends StatelessWidget {
  final ResumoDashboard resumo;
  final ValueChanged<int>? onNavigate;

  const _LinhaKpis({required this.resumo, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CartaoKpi(
            icone: Icons.today_outlined,
            rotulo: 'Vendas hoje',
            valor: '${resumo.qtdVendasHoje}',
            cor: AppColors.accent,
            onTap: () => onNavigate?.call(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CartaoKpi(
            icone: Icons.pending_actions_outlined,
            rotulo: 'Portab. pendentes',
            valor: '${resumo.portPendentes}',
            cor: AppColors.primary,
            onTap: () => onNavigate?.call(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CartaoKpi(
            icone: Icons.notifications_active_outlined,
            rotulo: 'Retornos hoje',
            valor: '${resumo.retornosHoje}',
            cor: resumo.retornosHoje > 0
                ? AppColors.danger
                : AppColors.textSecondary,
            onTap: () => onNavigate?.call(3),
          ),
        ),
      ],
    );
  }
}

class _CartaoCampanhas extends StatelessWidget {
  final List<ProgressoCampanha> campanhas;
  const _CartaoCampanhas({required this.campanhas});

  @override
  Widget build(BuildContext context) {
    return CartaoSecao(
      titulo: 'Campanhas ativas',
      acao: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaCampanhas()),
        ),
        child: const Text('Ver todas'),
      ),
      child: Column(
        children: campanhas.take(2).map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.campanha.nome,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Etiqueta(
                      texto: 'até ${Fmt.dataCurta(c.campanha.dataFim)}',
                      cor: AppColors.accent,
                      icone: Icons.flag_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BarraProgresso(valor: c.percGeral),
                const SizedBox(height: 4),
                Text(
                  '${(c.percGeral * 100).toStringAsFixed(0)}% · ${c.itens.length} produtos',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ListaProdutos extends StatelessWidget {
  final List<LinhaMeta> linhas;
  final List<LinhaMeta> todas;
  const _ListaProdutos({required this.linhas, required this.todas});

  @override
  Widget build(BuildContext context) {
    if (linhas.isEmpty) {
      return CartaoSecao(
        titulo: 'Produtos',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              const Text(
                'Cadastre as metas individuais mensais para acompanhar o desempenho por produto.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaMetasEditar()),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const RotuloBotao('CADASTRAR METAS'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CartaoSecao(
      titulo: 'Metas × Realizado',
      acao: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaMetasEditar()),
        ),
        child: const Text('Editar'),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: [for (final l in linhas) _LinhaProduto(linha: l)],
      ),
    );
  }
}

class _LinhaProduto extends StatelessWidget {
  final LinhaMeta linha;
  const _LinhaProduto({required this.linha});

  @override
  Widget build(BuildContext context) {
    final cor = AppColors.semaforo(linha.percRealizado);
    return InkWell(
      onTap: () => _detalhe(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    linha.produto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  Fmt.percentual(linha.percRealizado),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: cor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            BarraProgresso(valor: linha.percRealizado),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${Fmt.valorPorFormato(linha.realizadoMes, linha.formato)} de ${Fmt.valorPorFormato(linha.metaIndividual, linha.formato)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (linha.gap > 0)
                  Text(
                    'falta ${Fmt.valorPorFormato(linha.gap, linha.formato)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Etiqueta(texto: 'META BATIDA', cor: AppColors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _detalhe(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              linha.produto,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Formato: ${linha.formato}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _linhaDetalhe(
              'Meta da agência',
              Fmt.valorPorFormato(linha.metaMes, linha.formato),
            ),
            _linhaDetalhe(
              'Meta individual',
              Fmt.valorPorFormato(linha.metaIndividual, linha.formato),
            ),
            _linhaDetalhe(
              'Realizado no mês',
              Fmt.valorPorFormato(linha.realizadoMes, linha.formato),
            ),
            _linhaDetalhe(
              'Realizado hoje',
              Fmt.valorPorFormato(linha.realizadoHoje, linha.formato),
            ),
            _linhaDetalhe(
              'GAP',
              linha.gap > 0
                  ? Fmt.valorPorFormato(linha.gap, linha.formato)
                  : 'Meta atingida',
              cor: linha.gap > 0 ? AppColors.danger : AppColors.success,
            ),
            _linhaDetalhe(
              'Meta por dia útil',
              Fmt.valorPorFormato(linha.metaDia, linha.formato),
              cor: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDetalhe(String rotulo, String valor, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: cor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
