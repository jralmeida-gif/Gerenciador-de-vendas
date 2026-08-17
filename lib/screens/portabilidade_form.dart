import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Cadastro de pedido de portabilidade (aba "Cadastramento de portabilidade").
class TelaPortabilidadeForm extends StatefulWidget {
  final Portabilidade? port;
  const TelaPortabilidadeForm({super.key, this.port});

  @override
  State<TelaPortabilidadeForm> createState() => _TelaPortabilidadeFormState();
}

class _TelaPortabilidadeFormState extends State<TelaPortabilidadeForm> {
  final _formKey = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  DateTime? _dataNascimento;
  final _saldo = TextEditingController();
  final _prestacao = TextEditingController();
  final _qtd = TextEditingController();
  final _obs = TextEditingController();
  final _contrato = TextEditingController();

  bool _hoje = true;
  DateTime _data = DateTime.now();
  String? _convenio;
  bool _jaConfirmado = false;

  bool get _editando => widget.port != null;

  @override
  void initState() {
    super.initState();
    final p = widget.port;
    if (p != null) {
      _cpf.text = Fmt.cpf(p.cpf);
      _nome.text = p.nome;
      _telefone.text = Fmt.telefone(p.telefone);
      _dataNascimento = p.dataNascimento ?? context.read<AppState>().clientePorCpf(p.cpf)?.dataNascimento;
      _convenio = p.convenio;
      _saldo.text = Fmt.decimal(p.saldoDevedor);
      _prestacao.text = Fmt.decimal(p.valorPrestacao);
      _qtd.text = '${p.qtdPrestacoes}';
      _obs.text = p.observacoes;
      _data = p.data;
      _hoje = mesmoDia(p.data, DateTime.now());
      _jaConfirmado = p.confirmado;
      _contrato.text = p.numeroContrato;
    }
  }

  @override
  void dispose() {
    _cpf.dispose();
    _nome.dispose();
    _telefone.dispose();
    _saldo.dispose();
    _prestacao.dispose();
    _qtd.dispose();
    _obs.dispose();
    _contrato.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_convenio == null) {
      _msg('Selecione o convênio.', AppColors.warning);
      return;
    }
    final saldo = Fmt.parseNumero(_saldo.text);
    final prest = Fmt.parseNumero(_prestacao.text);
    final qtd = int.tryParse(Fmt.somenteDigitos(_qtd.text)) ?? 0;
    if (saldo <= 0) {
      _msg('Informe o saldo devedor.', AppColors.warning);
      return;
    }

    final estado = context.read<AppState>();
    final p = Portabilidade(
      id: widget.port?.id ?? estado.novoId(),
      data: _hoje ? DateTime.now() : _data,
      cpf: Fmt.somenteDigitos(_cpf.text),
      nome: _nome.text.trim(),
      telefone: Fmt.somenteDigitos(_telefone.text),
      dataNascimento: _dataNascimento,
      convenio: _convenio!,
      saldoDevedor: saldo,
      valorPrestacao: prest,
      qtdPrestacoes: qtd,
      confirmado: _jaConfirmado,
      numeroContrato: _jaConfirmado
          ? Fmt.contrato(_contrato.text)
          : (widget.port?.numeroContrato ?? ''),
      dataConfirmacao: _jaConfirmado
          ? (widget.port?.dataConfirmacao ?? DateTime.now())
          : widget.port?.dataConfirmacao,
      observacoes: _obs.text.trim(),
    );
    await estado.atualizarClienteConsolidado(
      cpf: p.cpf,
      nome: p.nome,
      telefone: p.telefone,
      dataNascimento: p.dataNascimento,
    );
    await estado.salvarPortabilidade(p);
    if (!mounted) return;

    if (_editando) {
      Navigator.pop(context);
      _msg('Portabilidade atualizada!', AppColors.success);
      return;
    }

    final outro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pedido registrado!'),
        content: Text(
          'Deseja cadastrar outra portabilidade para ${p.nome.split(' ').first}?',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Salvar e concluir'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Cadastrar outro pedido'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (outro == true) {
      setState(() {
        _saldo.clear();
        _prestacao.clear();
        _qtd.clear();
        _obs.clear();
        _contrato.clear();
        _jaConfirmado = false;
      });
      _msg('Dados do cliente mantidos.', AppColors.success);
    } else {
      Navigator.pop(context);
      _msg('Portabilidade cadastrada!', AppColors.success);
    }
  }

  void _limpar() {
    setState(() {
      _cpf.clear();
      _nome.clear();
      _telefone.clear();
      _dataNascimento = null;
      _saldo.clear();
      _prestacao.clear();
      _qtd.clear();
      _obs.clear();
      _contrato.clear();
      _convenio = null;
      _hoje = true;
      _jaConfirmado = false;
      _data = DateTime.now();
    });
  }

  void _msg(String texto, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final convenios = context.watch<AppState>().convenios;

    void navegarParaAba(int indice) {
      final selecionar = context.read<AppState>().onSelecionarAba;
      Navigator.of(context).pop();
      selecionar?.call(indice);
    }

    return Scaffold(
      bottomNavigationBar: MenuRodapeApp(
        abaSelecionada: 2,
        onSelecionar: navegarParaAba,
      ),
      body: Column(
        children: [
          HeaderCurvo(
            titulo: _editando ? 'Editar Portabilidade' : 'Nova Portabilidade',
            subtitulo: Fmt.data(DateTime.now()),
            mostrarVoltar: true,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  CartaoSecao(
                    titulo: 'Dados do cliente',
                    child: Column(
                      children: [
                        CampoTexto(
                          rotulo: 'CPF',
                          controller: _cpf,
                          dica: '000.000.000-00',
                          teclado: TextInputType.number,
                          formatadores: [CpfInputFormatter()],
                          prefixo: const Icon(Icons.badge_outlined, size: 20),
                          validador: (v) {
                            final d = Fmt.somenteDigitos(v ?? '');
                            if (d.isEmpty) return 'Informe o CPF';
                            if (d.length != 11) return 'CPF incompleto';
                            if (!cpfValido(d)) return 'CPF inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Nome do cliente',
                          controller: _nome,
                          capitalizacao: TextCapitalization.words,
                          prefixo: const Icon(Icons.person_outline, size: 20),
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Telefone',
                          controller: _telefone,
                          dica: '(00) 00000-0000',
                          teclado: TextInputType.phone,
                          formatadores: [TelefoneInputFormatter()],
                          prefixo: const Icon(Icons.phone_outlined, size: 20),
                          validador: (v) {
                            final d = Fmt.somenteDigitos(v ?? '');
                            if (d.isEmpty) return 'Informe o telefone';
                            if (d.length < 10) return 'Telefone incompleto';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CampoDataOpcional(
                          rotulo: 'Data de nascimento (opcional)',
                          valor: _dataNascimento,
                          onChanged: (data) => setState(() => _dataNascimento = data),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CartaoSecao(
                    titulo: 'Dados do contrato de origem',
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.today_outlined,
                                size: 19,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Pedido de hoje',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _hoje,
                                onChanged: (v) => setState(() {
                                  _hoje = v;
                                  if (v) _data = DateTime.now();
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (!_hoje) ...[
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: _escolherData,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data do pedido',
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 19,
                                ),
                              ),
                              child: Text(
                                Fmt.data(_data),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 2, bottom: 6),
                              child: Text(
                                'Convênio',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _convenio,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.account_balance_outlined,
                                  size: 20,
                                ),
                              ),
                              hint: const Text('Selecione...'),
                              items: convenios
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.nome,
                                      child: Text(
                                        '${c.nome}  ·  ${c.codigo}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _convenio = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Saldo devedor',
                          controller: _saldo,
                          dica: '0,00',
                          teclado: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          formatadores: [MoedaInputFormatter()],
                          prefixo: const Icon(Icons.attach_money, size: 20),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: CampoTexto(
                                rotulo: 'Valor da prestação',
                                controller: _prestacao,
                                dica: '0,00',
                                teclado: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                formatadores: [MoedaInputFormatter()],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: CampoTexto(
                                rotulo: 'Qtd. prest.',
                                controller: _qtd,
                                dica: '0',
                                teclado: TextInputType.number,
                                formatadores: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _jaConfirmado
                                ? AppColors.success.withValues(alpha: 0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _jaConfirmado
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                size: 19,
                                color: _jaConfirmado
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Já confirmada?',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _jaConfirmado,
                                onChanged: (v) =>
                                    setState(() => _jaConfirmado = v),
                              ),
                            ],
                          ),
                        ),
                        if (_jaConfirmado) ...[
                          const SizedBox(height: 14),
                          CampoTexto(
                            rotulo: 'Número do contrato',
                            controller: _contrato,
                            dica: '0000000-00',
                            teclado: TextInputType.number,
                            formatadores: [MaskInputFormatter('#######-##')],
                            prefixo: const Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Observação (opcional)',
                          controller: _obs,
                          maxLinhas: 3,
                          capitalizacao: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _editando
                              ? () => Navigator.pop(context)
                              : _limpar,
                          icon: const Icon(Icons.close, size: 18),
                          label: RotuloBotao(_editando ? 'CANCELAR' : 'LIMPAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _salvar,
                          icon: const Icon(Icons.check, size: 19),
                          label: RotuloBotao(_editando ? 'SALVAR' : 'INCLUIR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
