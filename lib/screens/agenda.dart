import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/whatsapp.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';
import 'cliente_form.dart';

class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _TelaAgendaState();
}

class _TelaAgendaState extends State<TelaAgenda> {
  late DateTime _diaSelecionado = _dia(DateTime.now());
  String _janela = '7';

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  int get _quantidadeDias => int.tryParse(_janela) ?? 7;

  List<_AgendaItem> _montarItens(AppState estado) {
    final itens = <_AgendaItem>[];
    for (final p in estado.prospeccoes) {
      if (!p.concluida && p.dataRetorno != null) {
        itens.add(
          _AgendaItem(
            nome: p.nome,
            cpf: p.cpf,
            tipo: 'Retorno de prospecção',
            detalhe: 'Próximo contato',
            data: _dia(p.dataRetorno!),
            icone: Icons.phone_in_talk_outlined,
            cor: AppColors.accent,
          ),
        );
      }
    }
    for (final p in estado.portPendentes) {
      itens.add(
        _AgendaItem(
          nome: p.nome,
          cpf: p.cpf,
          tipo: 'Portabilidade pendente',
          detalhe: 'Acompanhamento da portabilidade',
          data: _dia(p.data),
          icone: Icons.swap_horiz_outlined,
          cor: AppColors.warning,
        ),
      );
    }

    final ano = _diaSelecionado.year;
    for (final cliente in estado.clientes) {
      final nascimento = cliente.dataNascimento;
      if (nascimento == null) continue;
      for (final anoAniversario in [ano, ano + 1]) {
        if (nascimento.month == 2 && nascimento.day == 29 &&
            !_ehBissexto(anoAniversario)) {
          continue;
        }
        itens.add(
          _AgendaItem(
            nome: cliente.nome,
            cpf: cliente.cpf,
            tipo: 'Aniversário',
            detalhe: 'Data de nascimento informada',
            data: DateTime(anoAniversario, nascimento.month, nascimento.day),
            icone: Icons.cake_outlined,
            cor: AppColors.success,
          ),
        );
      }
    }

    itens.sort((a, b) {
      final porData = a.data.compareTo(b.data);
      return porData != 0 ? porData : a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return itens;
  }

  Future<void> _abrirCliente(BuildContext context, _AgendaItem item) async {
    final estado = context.read<AppState>();
    Cliente? cliente;
    for (final candidato in estado.clientes) {
      if (candidato.cpf == item.cpf) {
        cliente = candidato;
        break;
      }
    }
    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A ficha deste cliente não foi encontrada.')),
      );
      return;
    }
    final ficha = cliente;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _AgendaClienteFicha(
        cliente: ficha,
        onWhatsApp: () {
          Navigator.pop(sheetContext);
          _abrirWhatsApp(ficha);
        },
        onProdutos: () {
          Navigator.pop(sheetContext);
          _abrirProdutos(ficha);
        },
        onEditar: () {
          Navigator.pop(sheetContext);
          _editarCliente(ficha);
        },
        onNascimento: () {
          Navigator.pop(sheetContext);
          _editarNascimento(ficha);
        },
      ),
    );
  }

  Future<void> _abrirWhatsApp(Cliente cliente) async {
    final ok = await WhatsApp.abrir(
      telefone: cliente.telefone,
      mensagem: WhatsApp.saudacao(cliente.nome),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone inválido para abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _abrirProdutos(Cliente cliente) async {
    final estado = context.read<AppState>();
    final vendas = estado.vendas.where((v) => v.cpf == cliente.cpf).toList();
    final portabilidades = estado.portabilidades.where((p) => p.cpf == cliente.cpf).toList();
    final prospeccoes = estado.prospeccoes.where((p) => p.cpf == cliente.cpf).toList();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(title: Text('Produtos e processos de ${cliente.nome}')),
            if (vendas.isEmpty && portabilidades.isEmpty && prospeccoes.isEmpty)
              const ListTile(title: Text('Nenhum produto ou processo encontrado.')),
            ...vendas.map((v) => ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(v.produto),
                  subtitle: Text('Venda em ${Fmt.data(v.data)}'),
                )),
            ...portabilidades.map((p) => const ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Portabilidade'),
                )),
            ...prospeccoes.map((p) => ListTile(
                  leading: const Icon(Icons.phone_in_talk_outlined),
                  title: Text('Prospecção: ${p.produto}'),
                )),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Fechar'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarCliente(Cliente cliente) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TelaClienteForm(cliente: cliente)),
    );
  }

  Future<void> _editarNascimento(Cliente cliente) async {
    final data = await showDatePicker(
      context: context,
      initialDate: cliente.dataNascimento ?? DateTime(1980, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data de nascimento',
    );
    if (data == null || !mounted) return;
    await context.read<AppState>().salvarCliente(
          cliente.copyWith(dataNascimento: data),
        );
  }

  bool _ehBissexto(int ano) =>
      ano % 4 == 0 && (ano % 100 != 0 || ano % 400 == 0);

  bool _mesmoDia(DateTime a, DateTime b) => _dia(a) == _dia(b);

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final todos = _montarItens(estado);
    final inicio = _diaSelecionado;
    final seguinte = inicio.add(const Duration(days: 1));
    final limite = inicio.add(Duration(days: _quantidadeDias - 1));
    final periodo = todos
        .where((item) =>
            !item.data.isBefore(inicio) && !item.data.isAfter(limite))
        .toList();
    final doDia = periodo.where((item) => _mesmoDia(item.data, inicio)).toList();
    final doDiaSeguinte =
        periodo.where((item) => _mesmoDia(item.data, seguinte)).toList();
    final demais = periodo
        .where((item) => item.data.isAfter(seguinte))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(
            titulo: 'Agenda',
            subtitulo: 'Calendário, retornos e aniversários',
            mostrarVoltar: true,
            voltarGlobal: true,
            ajudaContextualTitulo: 'Agenda de pendências',
            ajudaContextualTexto:
                'Escolha uma data no calendário e consulte os compromissos do dia, do dia seguinte ou de uma janela maior.',
            ajudaContextualComoUsar:
                'Toque em um compromisso para abrir a ficha do cliente e usar as ações disponíveis, como WhatsApp. A janela de visualização não altera as regras de notificação.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                CartaoSecao(
                  titulo: 'Calendário',
                  child: _CalendarioFixo(
                    dataInicial: _diaSelecionado,
                    primeiraData: DateTime(2020),
                    ultimaData: DateTime(2100, 12, 31),
                    onDateChanged: (data) =>
                        setState(() => _diaSelecionado = _dia(data)),
                  ),
                ),
                const SizedBox(height: 14),
                CartaoSecao(
                  titulo: 'Janela de visualização',
                  child: DropdownButtonFormField<String>(
                    initialValue: _janela,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.date_range_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '2',
                        child: Text('Dia selecionado e dia seguinte'),
                      ),
                      DropdownMenuItem(
                        value: '7',
                        child: Text('Próximos 7 dias'),
                      ),
                      DropdownMenuItem(
                        value: '30',
                        child: Text('Próximos 30 dias'),
                      ),
                      DropdownMenuItem(
                        value: '60',
                        child: Text('Próximos 60 dias'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) setState(() => _janela = valor);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _SecaoAgenda(
                  titulo: 'Dia selecionado · ${Fmt.data(inicio)}',
                  itens: doDia,
                  vazio: 'Nenhum compromisso para esta data.',
                  onItemTap: (item) => _abrirCliente(context, item),
                ),
                const SizedBox(height: 14),
                _SecaoAgenda(
                  titulo: 'Dia seguinte · ${Fmt.data(seguinte)}',
                  itens: doDiaSeguinte,
                  vazio: 'Nenhum compromisso para o dia seguinte.',
                  onItemTap: (item) => _abrirCliente(context, item),
                ),
                if (_quantidadeDias > 2) ...[
                  const SizedBox(height: 14),
                  _SecaoAgenda(
                    titulo:
                        'Demais compromissos até ${Fmt.data(limite)}',
                    itens: demais,
                    mostrarData: true,
                    vazio: 'Nenhum compromisso adicional neste período.',
                    onItemTap: (item) => _abrirCliente(context, item),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarioFixo extends StatefulWidget {
  final DateTime dataInicial;
  final DateTime primeiraData;
  final DateTime ultimaData;
  final ValueChanged<DateTime> onDateChanged;

  const _CalendarioFixo({
    required this.dataInicial,
    required this.primeiraData,
    required this.ultimaData,
    required this.onDateChanged,
  });

  @override
  State<_CalendarioFixo> createState() => _CalendarioFixoState();
}

class _CalendarioFixoState extends State<_CalendarioFixo> {
  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  static const _diasSemana = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
  late DateTime _mesExibido;

  @override
  void initState() {
    super.initState();
    _mesExibido = DateTime(widget.dataInicial.year, widget.dataInicial.month);
  }

  @override
  void didUpdateWidget(covariant _CalendarioFixo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameMonth(oldWidget.dataInicial, widget.dataInicial)) {
      _mesExibido = DateTime(widget.dataInicial.year, widget.dataInicial.month);
    }
  }

  bool get _podeVoltar => _mesExibido.isAfter(
        DateTime(widget.primeiraData.year, widget.primeiraData.month),
      );

  bool get _podeAvancar => _mesExibido.isBefore(
        DateTime(widget.ultimaData.year, widget.ultimaData.month),
      );

  void _mudarMes(int delta) {
    if (delta < 0 && !_podeVoltar) return;
    if (delta > 0 && !_podeAvancar) return;
    setState(() {
      _mesExibido = DateTime(_mesExibido.year, _mesExibido.month + delta);
    });
  }

  List<DateTime?> _diasDoMes() {
    final primeiro = DateTime(_mesExibido.year, _mesExibido.month, 1);
    final quantidade = DateTime(_mesExibido.year, _mesExibido.month + 1, 0).day;
    final vaziosAntes = primeiro.weekday - 1;
    final dias = <DateTime?>[
      ...List<DateTime?>.filled(vaziosAntes, null),
      for (var dia = 1; dia <= quantidade; dia++)
        DateTime(_mesExibido.year, _mesExibido.month, dia),
    ];
    while (dias.length % 7 != 0) {
      dias.add(null);
    }
    return dias;
  }

  bool _permitida(DateTime data) =>
      !data.isBefore(widget.primeiraData) && !data.isAfter(widget.ultimaData);

  @override
  Widget build(BuildContext context) {
    final dias = _diasDoMes();
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: _podeVoltar ? () => _mudarMes(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_meses[_mesExibido.month - 1]} de ${_mesExibido.year}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              onPressed: _podeAvancar ? () => _mudarMes(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: _diasSemana
              .map(
                (dia) => Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(dias.length ~/ 7, (semana) {
          final diasDaSemana = dias.sublist(semana * 7, semana * 7 + 7);
          return Row(
            children: diasDaSemana.map((data) {
              if (data == null) {
                return const Expanded(child: SizedBox(height: 42));
              }
              final selecionada = DateUtils.isSameDay(data, widget.dataInicial);
              final hoje = DateUtils.isSameDay(data, DateTime.now());
              final permitida = _permitida(data);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    onTap: permitida ? () => widget.onDateChanged(data) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selecionada
                            ? AppColors.primary
                            : hoje
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: hoje && !selecionada
                            ? Border.all(color: AppColors.accent)
                            : null,
                      ),
                      child: Text(
                        '${data.day}',
                        style: TextStyle(
                          color: selecionada
                              ? Colors.white
                              : permitida
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                          fontWeight: selecionada || hoje
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

class _AgendaItem {
  final String nome;
  final String cpf;
  final String tipo;
  final String detalhe;
  final DateTime data;
  final IconData icone;
  final Color cor;

  const _AgendaItem({
    required this.nome,
    required this.cpf,
    required this.tipo,
    required this.detalhe,
    required this.data,
    required this.icone,
    required this.cor,
  });
}

class _SecaoAgenda extends StatelessWidget {
  final String titulo;
  final List<_AgendaItem> itens;
  final String vazio;
  final bool mostrarData;
  final ValueChanged<_AgendaItem>? onItemTap;

  const _SecaoAgenda({
    required this.titulo,
    required this.itens,
    required this.vazio,
    this.mostrarData = false,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return CartaoSecao(
      titulo: titulo,
      child: itens.isEmpty
          ? Text(vazio, style: const TextStyle(color: AppColors.textSecondary))
          : Column(
              children: itens.map((item) {
                final complemento = mostrarData
                    ? '${Fmt.data(item.data)} · ${item.detalhe}'
                    : item.detalhe;
                return InkWell(
                  onTap: onItemTap == null ? null : () => onItemTap!(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: item.cor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icone, color: item.cor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.tipo,
                              style: TextStyle(
                                color: item.cor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              complemento,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onItemTap != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                );
              }).toList(),
            ),
    );
  }
}


class _AgendaClienteFicha extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onWhatsApp;
  final VoidCallback onProdutos;
  final VoidCallback onEditar;
  final VoidCallback onNascimento;

  const _AgendaClienteFicha({
    required this.cliente,
    required this.onWhatsApp,
    required this.onProdutos,
    required this.onEditar,
    required this.onNascimento,
  });

  @override
  Widget build(BuildContext context) {
    final temTelefone = cliente.telefone.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ficha do cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                cliente.nome,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${Fmt.cpf(cliente.cpf)} · ${Fmt.telefone(cliente.telefone)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                cliente.dataNascimento == null
                    ? 'Nascimento não informado'
                    : 'Nascimento: ${Fmt.data(cliente.dataNascimento!)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (cliente.observacoes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  cliente.observacoes,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  FilledButton.icon(
                    onPressed: temTelefone ? onWhatsApp : null,
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onProdutos,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Produtos comprados'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onNascimento,
                    icon: const Icon(Icons.cake_outlined, size: 18),
                    label: const Text('Nascimento'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
