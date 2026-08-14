import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/relatorios_pdf.dart';
import '../services/whatsapp.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Central de relatórios — os 6 relatórios da planilha original.
class TelaRelatorios extends StatelessWidget {
  const TelaRelatorios({super.key});

  static const _tipos = [
    TipoRel(
      id: 'venda_dia',
      titulo: 'Venda do dia',
      descricao: 'Todas as vendas lançadas em uma data específica',
      icone: Icons.today_outlined,
      cor: AppColors.primary,
    ),
    TipoRel(
      id: 'venda_cliente',
      titulo: 'Venda por Cliente / Período',
      descricao: 'Histórico de compras de um cliente no período',
      icone: Icons.person_search_outlined,
      cor: AppColors.primaryLight,
    ),
    TipoRel(
      id: 'venda_produto',
      titulo: 'Venda por Produto / Período',
      descricao: 'Desempenho de cada produto no período',
      icone: Icons.inventory_2_outlined,
      cor: AppColors.accent,
    ),
    TipoRel(
      id: 'venda_foco',
      titulo: 'Vendas agrupadas por foco',
      descricao: 'Escolha o campo principal e veja os demais dados indexados',
      icone: Icons.account_tree_outlined,
      cor: AppColors.primary,
    ),
    TipoRel(
      id: 'prospeccao',
      titulo: 'Prospecção / Período',
      descricao: 'Clientes prospectados e retornos agendados',
      icone: Icons.phone_in_talk_outlined,
      cor: AppColors.success,
    ),
    TipoRel(
      id: 'portabilidade',
      titulo: 'Portabilidades Efetivadas / Período',
      descricao: 'Portabilidades confirmadas com nº de contrato',
      icone: Icons.swap_horiz_outlined,
      cor: AppColors.warning,
    ),
    TipoRel(
      id: 'contatos',
      titulo: 'Listagem de Contatos por Produto',
      descricao: 'Telefones dos clientes que compraram um produto',
      icone: Icons.contacts_outlined,
      cor: AppColors.textSecondary,
    ),
    TipoRel(
      id: 'clientes',
      titulo: 'Ficha Consolidada de Clientes',
      descricao: 'Clientes, produtos contratados e histórico comercial',
      icone: Icons.badge_outlined,
      cor: AppColors.primaryLight,
    ),
    TipoRel(
      id: 'historico_desempenho',
      titulo: 'Histórico de Desempenho',
      descricao: 'Análise percentual das metas por mês, semestre ou ano',
      icone: Icons.insights_outlined,
      cor: AppColors.success,
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(
            titulo: 'Relatórios',
            subtitulo: 'Gere e compartilhe em PDF',
            mostrarVoltar: false,
            ajudaContextualTitulo: 'Relatórios',
            ajudaContextualTexto: 'Consulta e organiza os dados sem alterar os lançamentos.',
            ajudaContextualComoUsar: 'Escolha o relatório, período, foco e filtros. Use a ficha consolidada para pesquisar clientes.',
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _tipos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = _tipos[i];
                return InkWell(
                  onTap: () {
                    final abrir = context.read<AppState>().onAbrirRelatorio;
                    final pagina = TelaRelatorioParametros(tipo: t);
                    if (abrir != null) {
                      abrir(pagina);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
                    }
                  },
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: t.cor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(t.icone, color: t.cor, size: 22),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.titulo,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.descricao,
                                style: const TextStyle(
                                  fontSize: 12.3,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TipoRel {
  final String id;
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  const TipoRel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
  });
}

// ---------------------------------------------------------------------------

class TelaRelatorioParametros extends StatefulWidget {
  final TipoRel tipo;
  const TelaRelatorioParametros({super.key, required this.tipo});

  @override
  State<TelaRelatorioParametros> createState() =>
      _TelaRelatorioParametrosState();
}

class _TelaRelatorioParametrosState extends State<TelaRelatorioParametros> {
  DateTime _data = DateTime.now();
  late DateTime _inicio = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _fim = DateTime.now();
  String? _produto;
  String _foco = 'cliente';
  String _periodoHistorico = 'mensal';
  final _cliente = TextEditingController();
  bool _gerando = false;

  String get _tipoId => widget.tipo.id;

  bool get _precisaData => _tipoId == 'venda_dia';
  bool get _precisaPeriodo => !_precisaData && _tipoId != 'contatos' && _tipoId != 'clientes' && _tipoId != 'historico_desempenho';
  bool get _ehHistorico => _tipoId == 'historico_desempenho';
  bool get _precisaProduto =>
      _tipoId == 'contatos' || _tipoId == 'venda_produto';
  bool get _precisaCliente => _tipoId == 'venda_cliente' || _tipoId == 'clientes';
  bool get _precisaFoco => _tipoId == 'venda_foco';

  @override
  void dispose() {
    _cliente.dispose();
    super.dispose();
  }

  Future<void> _escolher(String qual) async {
    final base = qual == 'data'
        ? _data
        : qual == 'inicio'
        ? _inicio
        : _fim;
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d == null) return;
    setState(() {
      if (qual == 'data') {
        _data = d;
      } else if (qual == 'inicio') {
        _inicio = d;
        if (_fim.isBefore(_inicio)) _fim = _inicio;
      } else {
        _fim = d;
      }
    });
  }

  bool _noPeriodo(DateTime d) {
    final a = DateTime(_inicio.year, _inicio.month, _inicio.day);
    final b = DateTime(_fim.year, _fim.month, _fim.day, 23, 59, 59);
    return !d.isBefore(a) && !d.isAfter(b);
  }

  Future<void> _gerar() async {
    if (_precisaProduto && _tipoId == 'contatos' && _produto == null) {
      _aviso('Selecione o produto.');
      return;
    }
    setState(() => _gerando = true);
    try {
      final estado = context.read<AppState>();
      final dados = _montar(estado);
      final bytes = await RelatoriosPdf.gerar(
        titulo: widget.tipo.titulo,
        periodo: dados.periodo,
        colunas: dados.colunas,
        linhas: dados.linhas,
        alinharDireita: dados.direita,
        resumo: dados.resumo,
        usuario: estado.nomeUsuario,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
        name: '${widget.tipo.titulo}.pdf',
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
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

  _DadosRel _montar(AppState estado) {
    switch (_tipoId) {
      case 'historico_desempenho':
        {
          final linhas = <List<String>>[];
          var somaAtingimentos = 0.0;
          var quantidadeComMeta = 0;
          for (var cursor = DateTime(_inicio.year, _inicio.month); !cursor.isAfter(DateTime(_fim.year, _fim.month)); cursor = DateTime(cursor.year, cursor.month + 1)) {
            final mesRef = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
            for (final produto in estado.produtos) {
              final meta = estado.metaMensalDoProduto(produto.nome, mesRef);
              final realizado = estado.realizadoProduto(produto.nome, DateTime(cursor.year, cursor.month, 1), DateTime(cursor.year, cursor.month + 1, 0));
              if (meta <= 0 && realizado <= 0) continue;
              final atingido = meta > 0 ? realizado / meta : 0.0;
              final atingidoConsolidado = atingido.clamp(0.0, 1.0).toDouble();
              final gap = (1 - atingidoConsolidado).clamp(0.0, 1.0).toDouble();
              if (meta > 0) {
                somaAtingimentos += atingidoConsolidado;
                quantidadeComMeta++;
              }
              linhas.add([
                '${cursor.month.toString().padLeft(2, '0')}/${cursor.year}',
                produto.nome,
                Fmt.valorPorFormato(meta, produto.formato),
                Fmt.valorPorFormato(realizado, produto.formato),
                '${(atingido * 100).toStringAsFixed(0)}%',
                '${(gap * 100).toStringAsFixed(0)}%',
              ]);
            }
          }
          final atingimentoGeral = quantidadeComMeta > 0 ? somaAtingimentos / quantidadeComMeta : 0.0;
          final gapGeral = (1 - atingimentoGeral).clamp(0.0, 1.0).toDouble();
          return _DadosRel(
            periodo: 'Período $_periodoHistorico: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)}',
            colunas: const ['Mês', 'Produto', 'Meta', 'Realizado', '% atingido', 'GAP %'],
            linhas: linhas,
            direita: const [2, 3, 4, 5],
            resumo: '${linhas.length} linha(s) · Realizado médio: ${(atingimentoGeral * 100).toStringAsFixed(0)}% · GAP médio: ${(gapGeral * 100).toStringAsFixed(0)}%',
          );
        }

      case 'venda_dia':
        {
          final itens =
              estado.vendas.where((v) => mesmoDia(v.data, _data)).toList()
                ..sort((a, b) => a.nome.compareTo(b.nome));
          final total = itens.fold<double>(0, (s, v) => s + v.valorRealizado);
          return _DadosRel(
            periodo: 'Data: ${Fmt.data(_data)}',
            colunas: const ['Cliente', 'CPF', 'Telefone', 'Produto', 'Valor'],
            linhas: itens
                .map(
                  (v) => [
                    v.nome,
                    Fmt.cpf(v.cpf),
                    Fmt.telefone(v.telefone),
                    v.produto,
                    Fmt.valorPorFormato(
                      v.valorRealizado,
                      estado.formatoDoProduto(v.produto),
                    ),
                  ],
                )
                .toList(),
            direita: const [4],
            resumo:
                '${itens.length} venda(s) no dia · Total em valor: ${Fmt.moeda(total)}',
          );
        }

      case 'venda_cliente':
        {
          final q = _cliente.text.trim().toLowerCase();
          final digitos = Fmt.somenteDigitos(q);
          var itens = estado.vendas.where((v) => _noPeriodo(v.data)).toList();
          if (q.isNotEmpty) {
            itens = itens
                .where(
                  (v) =>
                      v.nome.toLowerCase().contains(q) ||
                      (digitos.isNotEmpty && v.cpf.contains(digitos)),
                )
                .toList();
          }
          itens.sort((a, b) {
            final c = a.nome.compareTo(b.nome);
            return c != 0 ? c : a.data.compareTo(b.data);
          });
          final total = itens.fold<double>(0, (s, v) => s + v.valorRealizado);
          final clientes = itens.map((v) => v.cpf).toSet().length;
          return _DadosRel(
            periodo:
                'Período: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)}${q.isEmpty ? '' : ' · Filtro: ${_cliente.text.trim()}'}',
            colunas: const ['Data', 'Cliente', 'CPF', 'Produto', 'Valor'],
            linhas: itens
                .map(
                  (v) => [
                    Fmt.data(v.data),
                    v.nome,
                    Fmt.cpf(v.cpf),
                    v.produto,
                    Fmt.valorPorFormato(
                      v.valorRealizado,
                      estado.formatoDoProduto(v.produto),
                    ),
                  ],
                )
                .toList(),
            direita: const [4],
            resumo:
                '$clientes cliente(s) · ${itens.length} venda(s) · Total em valor: ${Fmt.moeda(total)}',
          );
        }

      case 'venda_produto':
        {
          var itens = estado.vendas.where((v) => _noPeriodo(v.data)).toList();
          if (_produto != null) {
            itens = itens.where((v) => v.produto == _produto).toList();
          }
          final mapa = <String, List<Venda>>{};
          for (final v in itens) {
            mapa.putIfAbsent(v.produto, () => []).add(v);
          }
          final chaves = mapa.keys.toList()..sort();
          final linhas = <List<String>>[];
          for (final k in chaves) {
            final lista = mapa[k]!;
            final soma = lista.fold<double>(0, (s, v) => s + v.valorRealizado);
            final fmt = estado.formatoDoProduto(k);
            final indiv = estado.metaDoProduto(k);
            linhas.add([
              k,
              fmt,
              '${lista.length}',
              Fmt.valorPorFormato(soma, fmt),
              indiv > 0 ? Fmt.valorPorFormato(indiv, fmt) : '—',
              indiv > 0 ? Fmt.percentual(soma / indiv) : '—',
            ]);
          }
          final total = itens.fold<double>(0, (s, v) => s + v.valorRealizado);
          return _DadosRel(
            periodo:
                'Período: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)}${_produto == null ? ' · Todos os produtos' : ' · $_produto'}',
            colunas: const [
              'Produto',
              'Formato',
              'Qtd lanç.',
              'Realizado',
              'Meta indiv.',
              '% atingido',
            ],
            linhas: linhas,
            direita: const [2, 3, 4, 5],
            resumo:
                '${chaves.length} produto(s) · ${itens.length} lançamento(s) · Total em valor: ${Fmt.moeda(total)}',
          );
        }

      case 'venda_foco':
        {
          final itens = estado.vendas.where((v) => _noPeriodo(v.data)).toList();
          final mapa = <String, List<Venda>>{};
          for (final v in itens) {
            final chave = _foco == 'cliente'
                ? (v.cpf.isNotEmpty ? v.cpf : v.nome.trim().toLowerCase())
                : _foco == 'produto'
                    ? v.produto
                    : Fmt.data(v.data);
            mapa.putIfAbsent(chave, () => []).add(v);
          }
          final chaves = mapa.keys.toList()..sort();
          final linhas = <List<String>>[];
          for (final chave in chaves) {
            final grupo = mapa[chave]!;
            final nomes = grupo.map((v) => v.nome).toSet().toList()..sort();
            final produtos = grupo.map((v) => v.produto).toSet().toList()..sort();
            final total = grupo.fold<double>(0, (s, v) => s + v.valorRealizado);
            final principal = _foco == 'cliente'
                ? grupo.first.nome
                : _foco == 'produto'
                    ? chave
                    : chave;
            final detalhamento = _foco == 'cliente'
                ? produtos.join(', ')
                : _foco == 'produto'
                    ? nomes.join(', ')
                    : nomes.join(', ');
            linhas.add([principal, detalhamento, '${grupo.length}', Fmt.moeda(total)]);
          }
          return _DadosRel(
            periodo: 'Período: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)} · Foco: ${_foco == 'cliente' ? 'Cliente/CPF' : _foco == 'produto' ? 'Produto' : 'Data'}',
            colunas: const ['Campo principal', 'Dados relacionados', 'Qtd.', 'Total'],
            linhas: linhas,
            direita: const [2, 3],
            resumo: '${linhas.length} grupo(s) · ${itens.length} lançamento(s) · Total: ${Fmt.moeda(itens.fold<double>(0, (s, v) => s + v.valorRealizado))}',
          );
        }

      case 'prospeccao':
        {
          final itens =
              estado.prospeccoes.where((p) => _noPeriodo(p.data)).toList()
                ..sort((a, b) => a.data.compareTo(b.data));
          final pendentes = itens.where((p) => !p.concluida).length;
          return _DadosRel(
            periodo: 'Período: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)}',
            colunas: const [
              'Data',
              'Cliente',
              'Telefone',
              'Produto',
              'Retorno',
              'Situação',
            ],
            linhas: itens
                .map(
                  (p) => [
                    Fmt.data(p.data),
                    p.nome,
                    Fmt.telefone(p.telefone),
                    p.produto,
                    p.dataRetorno == null ? '—' : Fmt.data(p.dataRetorno!),
                    p.concluida ? 'Concluída' : 'Em aberto',
                  ],
                )
                .toList(),
            resumo: '${itens.length} prospecção(ões) · $pendentes em aberto',
          );
        }

      case 'portabilidade':
        {
          final itens =
              estado.portabilidades
                  .where(
                    (p) =>
                        p.confirmado && _noPeriodo(p.dataConfirmacao ?? p.data),
                  )
                  .toList()
                ..sort(
                  (a, b) => (a.dataConfirmacao ?? a.data).compareTo(
                    b.dataConfirmacao ?? b.data,
                  ),
                );
          final saldo = itens.fold<double>(0, (s, p) => s + p.saldoDevedor);
          return _DadosRel(
            periodo: 'Período: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)}',
            colunas: const [
              'Confirmação',
              'Cliente',
              'Convênio',
              'Contrato',
              'Saldo devedor',
              'Prestação',
              'Qtd',
            ],
            linhas: itens
                .map(
                  (p) => [
                    Fmt.data(p.dataConfirmacao ?? p.data),
                    p.nome,
                    p.convenio,
                    p.numeroContrato.isEmpty ? '—' : p.numeroContrato,
                    Fmt.moeda(p.saldoDevedor),
                    Fmt.moeda(p.valorPrestacao),
                    '${p.qtdPrestacoes}',
                  ],
                )
                .toList(),
            direita: const [4, 5, 6],
            resumo:
                '${itens.length} portabilidade(s) efetivada(s) · Saldo total: ${Fmt.moeda(saldo)}',
          );
        }

      case 'contatos':
        {
          var itens = estado.vendas.where((v) => _noPeriodo(v.data)).toList();
          if (_produto != null) itens = itens.where((v) => v.produto == _produto).toList();
          final mapa = <String, Venda>{};
          for (final v in itens) {
            mapa.putIfAbsent(v.cpf, () => v);
          }
          final linhas = mapa.values.map((v) => [v.nome, Fmt.cpf(v.cpf), Fmt.telefone(v.telefone), v.produto]).toList();
          return _DadosRel(
            periodo: 'Período: ${Fmt.data(_inicio)} a ${Fmt.data(_fim)}',
            colunas: const ['Cliente', 'CPF', 'Telefone', 'Produto'],
            linhas: linhas,
            direita: const [],
            resumo: '${linhas.length} contato(s)',
          );
        }
      case 'clientes':
        {
          final q = _cliente.text.trim().toLowerCase();
          final digitos = Fmt.somenteDigitos(q);
          var lista = estado.clientes;
          if (q.isNotEmpty) {
            lista = lista.where((c) => c.nome.toLowerCase().contains(q) || (digitos.isNotEmpty && c.cpf.contains(digitos))).toList();
          }
          final linhas = lista.map((c) {
            final produtos = <String>{
              ...estado.vendas.where((v) => v.cpf == c.cpf).map((v) => v.produto),
              ...estado.prospeccoes.where((p) => p.cpf == c.cpf).map((p) => 'Prospecção: ${p.produto}'),
              ...estado.portabilidades.where((p) => p.cpf == c.cpf).map((_) => 'Portabilidade'),
            };
            return [
              c.nome,
              Fmt.cpf(c.cpf),
              Fmt.telefone(c.telefone),
              c.dataNascimento == null ? '—' : Fmt.data(c.dataNascimento!),
              produtos.isEmpty ? '—' : produtos.join(', '),
            ];
          }).toList();
          return _DadosRel(
            periodo: 'Clientes do usuário${q.isEmpty ? '' : ' · Filtro: ${_cliente.text.trim()}'}',
            colunas: const ['Cliente', 'CPF', 'Telefone', 'Nascimento', 'Produtos / processos'],
            linhas: linhas,
            direita: const [],
            resumo: '${linhas.length} cliente(s) consolidado(s)',
          );
        }
      default:
        {
          final itens = estado.vendas
              .where((v) => v.produto == _produto)
              .toList();
          final porCpf = <String, Venda>{};
          for (final v in itens) {
            porCpf.putIfAbsent(v.cpf, () => v);
          }
          final lista = porCpf.values.toList()
            ..sort((a, b) => a.nome.compareTo(b.nome));
          return _DadosRel(
            periodo: 'Produto: ${_produto ?? '—'}',
            colunas: const ['Cliente', 'CPF', 'Telefone', 'Última compra'],
            linhas: lista
                .map(
                  (v) => [
                    v.nome,
                    Fmt.cpf(v.cpf),
                    Fmt.telefone(v.telefone),
                    Fmt.data(v.data),
                  ],
                )
                .toList(),
            resumo: '${lista.length} cliente(s) distinto(s)',
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: widget.tipo.titulo,
            subtitulo: 'Defina os parâmetros e gere o PDF',
            mostrarVoltar: true,
            voltarGlobal: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                CartaoSecao(
                  titulo: 'Parâmetros',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_ehHistorico) ...[
                        const Text('Período de análise', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _periodoHistorico,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.date_range_outlined, size: 20)),
                          items: const [
                            DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                            DropdownMenuItem(value: 'semestral', child: Text('Semestral')),
                            DropdownMenuItem(value: 'anual', child: Text('Anual')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            final n = DateTime.now();
                            setState(() {
                              _periodoHistorico = v;
                              if (v == 'mensal') {
                                _inicio = DateTime(n.year, n.month, 1);
                                _fim = DateTime(n.year, n.month + 1, 0);
                              } else if (v == 'semestral') {
                                _inicio = DateTime(n.year, n.month - 5, 1);
                                _fim = DateTime(n.year, n.month + 1, 0);
                              } else {
                                _inicio = DateTime(n.year, 1, 1);
                                _fim = DateTime(n.year, 12, 31);
                              }
                            });
                          },
                        ),
                      ],
                      if (_precisaData)
                        _Data(
                          rotulo: 'Data do relatório',
                          valor: Fmt.data(_data),
                          onTap: () => _escolher('data'),
                        ),
                      if (_precisaPeriodo)
                        Row(
                          children: [
                            Expanded(
                              child: _Data(
                                rotulo: 'De',
                                valor: Fmt.data(_inicio),
                                onTap: () => _escolher('inicio'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Data(
                                rotulo: 'Até',
                                valor: Fmt.data(_fim),
                                onTap: () => _escolher('fim'),
                              ),
                            ),
                          ],
                        ),
                      if (_precisaPeriodo) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            _atalho('Este mês', () {
                              final n = DateTime.now();
                              setState(() {
                                _inicio = DateTime(n.year, n.month, 1);
                                _fim = n;
                              });
                            }),
                            _atalho('Mês passado', () {
                              final n = DateTime.now();
                              setState(() {
                                _inicio = DateTime(n.year, n.month - 1, 1);
                                _fim = DateTime(n.year, n.month, 0);
                              });
                            }),
                            _atalho('Últimos 7 dias', () {
                              final n = DateTime.now();
                              setState(() {
                                _inicio = n.subtract(const Duration(days: 6));
                                _fim = n;
                              });
                            }),
                          ],
                        ),
                      ],
                      if (_precisaFoco) ...[
                        const SizedBox(height: 14),
                        const Text('Campo principal', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _foco,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.account_tree_outlined, size: 20)),
                          items: const [
                            DropdownMenuItem(value: 'cliente', child: Text('Cliente / CPF')),
                            DropdownMenuItem(value: 'produto', child: Text('Produto')),
                            DropdownMenuItem(value: 'data', child: Text('Data')),
                          ],
                          onChanged: (v) { if (v != null) setState(() => _foco = v); },
                        ),
                      ],
                      if (_precisaCliente) ...[
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Cliente (nome ou CPF)',
                          controller: _cliente,
                          dica: 'Deixe vazio para incluir todos',
                          prefixo: const Icon(
                            Icons.person_search_outlined,
                            size: 20,
                          ),
                        ),
                      ],
                      if (_precisaProduto) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Produto',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _produto,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: _tipoId == 'venda_produto'
                                ? 'Todos os produtos'
                                : 'Selecione o produto',
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                            ),
                          ),
                          items: [
                            if (_tipoId == 'venda_produto')
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Todos os produtos',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ...estado.produtos.map(
                              (p) => DropdownMenuItem(
                                value: p.nome,
                                child: Text(
                                  p.nome,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _produto = v),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_tipoId == 'clientes') ...[
                  const SizedBox(height: 14),
                  _EditorDatasNascimento(
                    clientes: estado.clientes.where((c) {
                      final q = _cliente.text.trim().toLowerCase();
                      final digitos = Fmt.somenteDigitos(q);
                      return q.isEmpty || c.nome.toLowerCase().contains(q) || (digitos.isNotEmpty && c.cpf.contains(digitos));
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                _Previa(dados: _montar(estado)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _gerando ? null : _gerar,
            icon: _gerando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: RotuloBotao(_gerando ? 'GERANDO...' : 'GERAR PDF'),
          ),
        ),
      ),
    );
  }

  Widget _atalho(String texto, VoidCallback onTap) => ActionChip(
    label: Text(
      texto,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
    ),
    onPressed: onTap,
    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    visualDensity: VisualDensity.compact,
  );
}

class _EditorDatasNascimento extends StatelessWidget {
  final List<Cliente> clientes;
  const _EditorDatasNascimento({required this.clientes});

  Future<void> _editar(BuildContext context, Cliente cliente) async {
    final nome = TextEditingController(text: cliente.nome);
    final telefone = TextEditingController(text: cliente.telefone);
    final observacoes = TextEditingController(text: cliente.observacoes);
    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: telefone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone')),
              TextField(controller: observacoes, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (salvo != true || !context.mounted) return;
    await context.read<AppState>().salvarCliente(cliente.copyWith(nome: nome.text.trim(), telefone: Fmt.somenteDigitos(telefone.text), observacoes: observacoes.text.trim()));
  }

  Future<void> _produtos(BuildContext context, Cliente cliente) async {
    final estado = context.read<AppState>();
    final vendas = estado.vendas.where((v) => v.cpf == cliente.cpf).toList();
    final portabilidades = estado.portabilidades.where((p) => p.cpf == cliente.cpf).toList();
    final prospeccoes = estado.prospeccoes.where((p) => p.cpf == cliente.cpf).toList();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text('Produtos comprados por ${cliente.nome}')),
            if (vendas.isEmpty && portabilidades.isEmpty && prospeccoes.isEmpty)
              const ListTile(title: Text('Nenhum produto ou processo encontrado.')),
            ...vendas.map((v) => ListTile(leading: const Icon(Icons.shopping_bag_outlined), title: Text(v.produto), subtitle: Text('Venda em ${Fmt.data(v.data)}'))),
            ...portabilidades.map((p) => const ListTile(leading: Icon(Icons.swap_horiz), title: Text('Portabilidade'))),
            ...prospeccoes.map((p) => ListTile(leading: const Icon(Icons.phone_in_talk_outlined), title: Text('Prospecção: ${p.produto}'))),
          ],
        ),
      ),
    );
  }

  Future<void> _whatsapp(BuildContext context, Cliente cliente) async {
    final ok = await WhatsApp.abrir(telefone: cliente.telefone, mensagem: WhatsApp.saudacao(cliente.nome));
    if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone inválido para abrir o WhatsApp.')));
  }

  Future<void> _nascimento(BuildContext context, Cliente cliente) async {
    final data = await showDatePicker(
      context: context,
      initialDate: cliente.dataNascimento ?? DateTime(1980, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data de nascimento',
    );
    if (data == null || !context.mounted) return;
    await context.read<AppState>().salvarCliente(cliente.copyWith(dataNascimento: data));
  }

  @override
  Widget build(BuildContext context) {
    return CartaoSecao(
      titulo: 'Clientes',
      child: clientes.isEmpty
          ? const Text('Nenhum cliente encontrado.', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: clientes.map((cliente) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('${Fmt.cpf(cliente.cpf)} · ${Fmt.telefone(cliente.telefone)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(cliente.dataNascimento == null ? 'Nascimento não informado' : 'Nascimento: ${Fmt.data(cliente.dataNascimento!)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          TextButton.icon(onPressed: () => _produtos(context, cliente), icon: const Icon(Icons.shopping_bag_outlined, size: 16), label: const Text('Produtos comprados')),
                          TextButton.icon(onPressed: () => _whatsapp(context, cliente), icon: const Icon(Icons.chat_outlined, size: 16), label: const Text('WhatsApp')),
                          TextButton.icon(onPressed: () => _editar(context, cliente), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Editar')),
                          TextButton.icon(onPressed: () => _nascimento(context, cliente), icon: const Icon(Icons.cake_outlined, size: 16), label: const Text('Nascimento')),
                        ],
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
    );
  }
}

class _DadosRel {
  final String periodo;
  final List<String> colunas;
  final List<List<String>> linhas;
  final List<int> direita;
  final String? resumo;
  _DadosRel({
    required this.periodo,
    required this.colunas,
    required this.linhas,
    this.direita = const [],
    this.resumo,
  });
}

class _Previa extends StatelessWidget {
  final _DadosRel dados;
  const _Previa({required this.dados});

  @override
  Widget build(BuildContext context) {
    return CartaoSecao(
      titulo: 'Prévia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              dados.resumo ?? '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (dados.linhas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Nenhum registro encontrado com esses parâmetros.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            ...dados.linhas
                .take(5)
                .map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 6, right: 9),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l.take(3).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (dados.linhas.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${dados.linhas.length - 5} registro(s) no PDF',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}
