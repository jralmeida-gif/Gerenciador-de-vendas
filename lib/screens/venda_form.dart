import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Lançamento de venda — equivalente à aba "Lançamento de venda".
class TelaVendaForm extends StatefulWidget {
  final Venda? venda;

  /// Pré-preenchimento vindo de outra tela (ex.: converter prospecção em venda).
  final String? cpfInicial;
  final String? nomeInicial;
  final String? telefoneInicial;
  final String? produtoInicial;
  final String? prospeccaoOrigemId;

  const TelaVendaForm({
    super.key,
    this.venda,
    this.cpfInicial,
    this.nomeInicial,
    this.telefoneInicial,
    this.produtoInicial,
    this.prospeccaoOrigemId,
  });

  @override
  State<TelaVendaForm> createState() => _TelaVendaFormState();
}

class _TelaVendaFormState extends State<TelaVendaForm> {
  final _formKey = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  DateTime? _dataNascimento;
  String? _cpfComDadosPreenchidos;
  final _valor = TextEditingController();
  final _obs = TextEditingController();

  bool _vendaHoje = true;
  DateTime _data = DateTime.now();
  String? _produto;

  bool get _editando => widget.venda != null;

  @override
  void initState() {
    super.initState();
    final v = widget.venda;
    if (v != null) {
      _cpf.text = Fmt.cpf(v.cpf);
      _nome.text = v.nome;
      _telefone.text = Fmt.telefone(v.telefone);
      _cpfComDadosPreenchidos = v.cpf;
      _dataNascimento = v.dataNascimento ?? context.read<AppState>().clientePorCpf(v.cpf)?.dataNascimento;
      _produto = v.produto;
      _data = v.data;
      _vendaHoje = mesmoDia(v.data, DateTime.now());
      _obs.text = v.observacoes;
      _valor.text = Fmt.decimal(v.valorRealizado);
    } else {
      if (widget.cpfInicial != null) _cpf.text = Fmt.cpf(widget.cpfInicial!);
      if (widget.nomeInicial != null) _nome.text = widget.nomeInicial!;
      if (widget.telefoneInicial != null) {
        _telefone.text = Fmt.telefone(widget.telefoneInicial!);
      }
      final cpfInicial = Fmt.somenteDigitos(widget.cpfInicial ?? '');
      if (cpfInicial.isNotEmpty) {
        _cpfComDadosPreenchidos = cpfInicial.length == 11 ? cpfInicial : null;
        _dataNascimento = context.read<AppState>().clientePorCpf(cpfInicial)?.dataNascimento;
      }
      _produto = widget.produtoInicial;
    }
  }

  @override
  void dispose() {
    _cpf.dispose();
    _nome.dispose();
    _telefone.dispose();
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  String get _formatoAtual => _produto == null
      ? 'Valor'
      : context.read<AppState>().formatoDoProduto(_produto!);

  bool get _ehQuantidade => _formatoAtual.toLowerCase() == 'quantidade';

  void _preencherClientePorCpf(String texto) {
    final cpf = Fmt.somenteDigitos(texto);
    if (_cpfComDadosPreenchidos != null && _cpfComDadosPreenchidos != cpf) {
      _nome.clear();
      _telefone.clear();
      _cpfComDadosPreenchidos = null;
      if (mounted) setState(() => _dataNascimento = null);
    }
    if (cpf.length != 11 || !cpfValido(cpf)) return;
    final cliente = context.read<AppState>().clientePorCpf(cpf);
    if (cliente == null) return;
    _nome.text = cliente.nome;
    _telefone.text = Fmt.telefone(cliente.telefone);
    _cpfComDadosPreenchidos = cpf;
    if (mounted) setState(() => _dataNascimento = cliente.dataNascimento);
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
    if (_produto == null) {
      _aviso('Selecione um produto.');
      return;
    }
    final valorNum = Fmt.parseNumero(_valor.text);
    if (valorNum <= 0) {
      _aviso('Informe o valor realizado.');
      return;
    }

    final estado = context.read<AppState>();
    final dataFinal = _vendaHoje ? DateTime.now() : _data;

    final venda = Venda(
      id: widget.venda?.id ?? estado.novoId(),
      data: dataFinal,
      cpf: Fmt.somenteDigitos(_cpf.text),
      nome: _nome.text.trim(),
      telefone: Fmt.somenteDigitos(_telefone.text),
      dataNascimento: _dataNascimento,
      produto: _produto!,
      valorRealizado: valorNum,
      observacoes: _obs.text.trim(),
    );

    final clienteAtual = estado.clientePorCpf(venda.cpf);
    final nomeDiferente = clienteAtual != null &&
        clienteAtual.nome.trim().toLowerCase() != venda.nome.trim().toLowerCase();
    final telefoneDiferente = clienteAtual != null && clienteAtual.telefone != venda.telefone;
    final nascimentoDiferente = _dataNascimento != null && clienteAtual?.dataNascimento != _dataNascimento;
    if (clienteAtual != null && (nomeDiferente || telefoneDiferente || nascimentoDiferente)) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Divergência no cadastro'),
          content: Text(
            'Já existe um cliente com este CPF.\n\n'
            'Cadastro: ${clienteAtual.nome} / ${Fmt.telefone(clienteAtual.telefone)}\n'
            'Informado: ${venda.nome} / ${Fmt.telefone(venda.telefone)}\n\n'
            'Deseja atualizar o cadastro com os dados informados?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Corrigir')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Atualizar')),
          ],
        ),
      );
      if (!mounted || continuar != true) return;
      await estado.salvarCliente(clienteAtual.copyWith(
        nome: venda.nome,
        telefone: venda.telefone,
        dataNascimento: _dataNascimento ?? clienteAtual.dataNascimento,
      ));

      if (!mounted) return;
    } else if (clienteAtual == null) {
      await estado.salvarCliente(Cliente(
        cpf: venda.cpf,
        nome: venda.nome,
        telefone: venda.telefone,
        dataNascimento: _dataNascimento,
      ));
      if (!mounted) return;
    }

    final duplicada = estado.encontrarVendaDuplicada(venda);
    if (duplicada != null) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Possível duplicidade'),
          content: Text(
            'Já existe uma venda do mesmo CPF, produto e valor na data ${Fmt.data(duplicada.data)}.\n\n'
            'Produto: ${duplicada.produto}\nValor: ${Fmt.decimal(duplicada.valorRealizado)}\n\n'
            'Deseja registrar mesmo assim?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar mesmo assim')),
          ],
        ),
      );
      if (!mounted || continuar != true) return;
    }

    await estado.salvarVenda(venda);
    final prospeccaoOrigemId = widget.prospeccaoOrigemId;
    if (prospeccaoOrigemId != null) {
      Prospeccao? origem;
      for (final item in estado.prospeccoes) {
        if (item.id == prospeccaoOrigemId) {
          origem = item;
          break;
        }
      }
      if (origem != null && !origem.concluida) {
        await estado.salvarProspeccao(origem.copyWith(concluida: true));
      }
    }
    if (!mounted) return;

    if (_editando) {
      Navigator.pop(context);
      _sucesso('Venda atualizada!');
      return;
    }

    // Fluxo da planilha: perguntar se quer lançar outro produto p/ mesmo cliente.
    final outro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Venda registrada!'),
        content: Text(
          'Deseja lançar outro produto para ${venda.nome.split(' ').first}?',
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
            label: const Text('Cadastrar outro produto'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (outro == true) {
      setState(() {
        _produto = null;
        _valor.clear();
        _obs.clear();
      });
      _sucesso('Dados do cliente mantidos. Selecione o novo produto.');
    } else {
      Navigator.pop(context);
      _sucesso('Venda registrada com sucesso!');
    }
  }

  void _limpar() {
    setState(() {
      _cpf.clear();
      _cpfComDadosPreenchidos = null;
      _nome.clear();
      _telefone.clear();
      _valor.clear();
      _obs.clear();
      _produto = null;
      _vendaHoje = true;
      _data = DateTime.now();
    });
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final produtos = estado.produtosAtivos.toList();
    if (_produto != null && produtos.every((p) => p.nome != _produto)) {
      for (final p in estado.produtos) {
        if (p.nome == _produto) {
          produtos.add(p);
          break;
        }
      }
    }
    final vendasHoje = estado.vendas
        .where((v) => mesmoDia(v.data, DateTime.now()))
        .length;

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: _editando ? 'Editar Venda' : 'Lançamento de Venda',
            subtitulo: Fmt.data(DateTime.now()),
            mostrarVoltar: true,
            acoes: [
              if (!_editando)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$vendasHoje hoje',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
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
                          onChanged: _preencherClientePorCpf,
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
                          dica: 'Nome completo',
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
                    titulo: 'Dados da venda',
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
                                  'Venda de hoje',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _vendaHoje,
                                onChanged: (v) => setState(() {
                                  _vendaHoje = v;
                                  if (v) _data = DateTime.now();
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (!_vendaHoje) ...[
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: _escolherData,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data da venda',
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
                                'Produto',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _produto,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                ),
                              ),
                              hint: const Text('Selecione...'),
                              items: produtos
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.nome,
                                      child: Text(
                                        p.nome,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _produto = v;
                                _valor.clear();
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: _ehQuantidade
                              ? 'Quantidade realizada'
                              : 'Valor realizado',
                          controller: _valor,
                          dica: _ehQuantidade ? '0' : '0,00',
                          teclado: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          formatadores: _ehQuantidade
                              ? [FilteringTextInputFormatter.digitsOnly]
                              : [MoedaInputFormatter()],
                          prefixo: Icon(
                            _ehQuantidade ? Icons.numbers : Icons.attach_money,
                            size: 20,
                          ),
                          sufixo: _produto == null
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Align(
                                    widthFactor: 1,
                                    child: Text(
                                      _formatoAtual,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Observação (opcional)',
                          controller: _obs,
                          dica: 'Alguma anotação sobre a venda',
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
