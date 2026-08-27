import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

class TelaClienteForm extends StatefulWidget {
  final Cliente? cliente;

  const TelaClienteForm({super.key, this.cliente});

  @override
  State<TelaClienteForm> createState() => _TelaClienteFormState();
}

class _TelaClienteFormState extends State<TelaClienteForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cpf;
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _observacoes;
  DateTime? _nascimento;
  String? _cpfCarregado;
  String? _mensagemCpf;
  bool _salvando = false;

  bool get _editando => widget.cliente != null;
  bool get _atualizandoExistente => !_editando && _cpfCarregado != null;

  @override
  void initState() {
    super.initState();
    final cliente = widget.cliente;
    _cpf = TextEditingController(text: cliente == null ? '' : Fmt.cpf(cliente.cpf));
    _nome = TextEditingController(text: cliente?.nome ?? '');
    _telefone = TextEditingController(
      text: cliente == null ? '' : Fmt.telefone(cliente.telefone),
    );
    _observacoes = TextEditingController(text: cliente?.observacoes ?? '');
    _nascimento = cliente?.dataNascimento;
    _cpfCarregado = cliente?.cpf;
  }

  @override
  void dispose() {
    _cpf.dispose();
    _nome.dispose();
    _telefone.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _preencherPorCpf(String valor) {
    if (_editando) return;
    final cpf = Fmt.somenteDigitos(valor);
    if (_cpfCarregado != null && _cpfCarregado != cpf) {
      _nome.clear();
      _telefone.clear();
      _observacoes.clear();
      _nascimento = null;
      _cpfCarregado = null;
    }
    if (cpf.length != 11 || !cpfValido(cpf)) {
      if (mounted) {
        setState(() => _mensagemCpf = null);
      }
      return;
    }
    final existente = context.read<AppState>().clientePorCpf(cpf);
    if (!mounted) return;
    if (existente == null) {
      setState(() {
        _mensagemCpf = 'CPF disponível para um novo cadastro.';
        _cpfCarregado = null;
      });
      return;
    }
    _nome.text = existente.nome;
    _telefone.text = Fmt.telefone(existente.telefone);
    _observacoes.text = existente.observacoes;
    setState(() {
      _nascimento = existente.dataNascimento;
      _cpfCarregado = cpf;
      _mensagemCpf = 'Já existe uma ficha para este CPF. O salvamento atualizará os dados comuns.';
    });
  }

  String? _validarCpf(String? valor) {
    if (valor == null || !cpfValido(valor)) return 'Informe um CPF válido';
    return null;
  }

  String? _validarTelefone(String? valor) {
    final telefone = Fmt.somenteDigitos(valor ?? '');
    if (telefone.isNotEmpty && (telefone.length < 10 || telefone.length > 11)) {
      return 'Informe DDD e telefone completos';
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cpf = Fmt.somenteDigitos(_cpf.text);
    final cliente = Cliente(
      cpf: cpf,
      nome: _nome.text.trim(),
      telefone: Fmt.somenteDigitos(_telefone.text),
      dataNascimento: _nascimento,
      observacoes: _observacoes.text.trim(),
    );
    setState(() => _salvando = true);
    try {
      await context.read<AppState>().salvarCliente(cliente);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o cliente: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: _editando || _atualizandoExistente
                ? 'Editar cliente'
                : 'Cadastrar cliente',
            subtitulo: _editando || _atualizandoExistente
                ? 'Atualize a ficha consolidada'
                : 'Cadastre um cliente sem lançar uma venda',
            mostrarVoltar: true,
            ajudaContextualTitulo: 'Cadastro de cliente',
            ajudaContextualTexto:
                'Permite incluir uma ficha para relacionamento e ofertas futuras, mesmo sem venda cadastrada.',
            ajudaContextualComoUsar:
                'Informe o CPF, confira o preenchimento automático se a ficha já existir e salve os dados.',
            ajudaContextualAtencao:
                'A data de nascimento é opcional e pode alimentar a Agenda e os avisos de aniversário.',
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
                          rotulo: _editando || _atualizandoExistente ? 'CPF' : 'CPF *',
                          controller: _cpf,
                          dica: '000.000.000-00',
                          habilitado: !_editando,
                          teclado: TextInputType.number,
                          formatadores: [CpfInputFormatter()],
                          onChanged: _preencherPorCpf,
                          prefixo: const Icon(Icons.badge_outlined, size: 20),
                          validador: _validarCpf,
                        ),
                        if (_mensagemCpf != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _mensagemCpf!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Nome *',
                          controller: _nome,
                          dica: 'Nome completo',
                          capitalizacao: TextCapitalization.words,
                          prefixo: const Icon(Icons.person_outline, size: 20),
                          validador: (valor) => valor == null || valor.trim().isEmpty
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
                          validador: _validarTelefone,
                        ),
                        const SizedBox(height: 14),
                        CampoDataOpcional(
                          rotulo: 'Data de nascimento (opcional)',
                          valor: _nascimento,
                          onChanged: (valor) => setState(() => _nascimento = valor),
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Observações',
                          controller: _observacoes,
                          dica: 'Interesses ou informações para futuros contatos',
                          maxLinhas: 3,
                          capitalizacao: TextCapitalization.sentences,
                          prefixo: const Icon(Icons.notes_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Clientes cadastrados diretamente aparecem na ficha consolidada mesmo antes de qualquer venda, portabilidade ou prospecção.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: RotuloBotao(_salvando ? 'SALVANDO...' : 'SALVAR CLIENTE'),
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
