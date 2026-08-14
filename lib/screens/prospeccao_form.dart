import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Cadastro de prospecção — equivalente à aba "Prospecção" (tblprospec).
class TelaProspeccaoForm extends StatefulWidget {
  final Prospeccao? prospeccao;
  const TelaProspeccaoForm({super.key, this.prospeccao});

  @override
  State<TelaProspeccaoForm> createState() => _TelaProspeccaoFormState();
}

class _TelaProspeccaoFormState extends State<TelaProspeccaoForm> {
  final _formKey = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _obs = TextEditingController();

  bool _hoje = true;
  DateTime _data = DateTime.now();
  DateTime? _dataRetorno;
  String? _produto;

  bool get _editando => widget.prospeccao != null;

  @override
  void initState() {
    super.initState();
    final p = widget.prospeccao;
    if (p != null) {
      _cpf.text = Fmt.cpf(p.cpf);
      _nome.text = p.nome;
      _telefone.text = Fmt.telefone(p.telefone);
      _produto = p.produto;
      _data = p.data;
      _hoje = mesmoDia(p.data, DateTime.now());
      _dataRetorno = p.dataRetorno;
      _obs.text = p.observacao;
    } else {
      _dataRetorno = DateTime.now().add(const Duration(days: 3));
    }
  }

  @override
  void dispose() {
    _cpf.dispose();
    _nome.dispose();
    _telefone.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _escolherData({required bool retorno}) async {
    final base = retorno ? (_dataRetorno ?? DateTime.now()) : _data;
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d == null) return;
    setState(() {
      if (retorno) {
        _dataRetorno = d;
      } else {
        _data = d;
      }
    });
  }

  void _aviso(String msg, {bool erro = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erro ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_produto == null) {
      _aviso('Selecione o produto de interesse.');
      return;
    }
    final estado = context.read<AppState>();
    final data = _hoje ? DateTime.now() : _data;

    final registro = _editando
        ? widget.prospeccao!.copyWith(
            data: data,
            cpf: Fmt.somenteDigitos(_cpf.text),
            nome: _nome.text.trim(),
            telefone: Fmt.somenteDigitos(_telefone.text),
            produto: _produto,
            dataRetorno: _dataRetorno,
            observacao: _obs.text.trim(),
          )
        : Prospeccao(
            id: estado.novoId(),
            data: data,
            cpf: Fmt.somenteDigitos(_cpf.text),
            nome: _nome.text.trim(),
            telefone: Fmt.somenteDigitos(_telefone.text),
            produto: _produto!,
            dataRetorno: _dataRetorno,
            observacao: _obs.text.trim(),
          );

    await estado.salvarProspeccao(registro);
    if (!mounted) return;

    if (_editando) {
      Navigator.pop(context);
      _aviso('Prospecção atualizada.', erro: false);
      return;
    }

    final outro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prospecção registrada'),
        content: Text(
          'Deseja registrar outro produto de interesse para '
          '${_nome.text.trim()}?',
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Salvar e finalizar'),
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
        _obs.clear();
      });
      _aviso(
        'Dados do cliente mantidos. Escolha o próximo produto.',
        erro: false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: _editando ? 'Editar prospecção' : 'Nova prospecção',
            subtitulo: 'Cliente com interesse em produto',
            mostrarVoltar: true,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  CartaoSecao(
                    titulo: 'Cliente',
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
                          rotulo: 'Nome',
                          controller: _nome,
                          dica: 'Nome completo',
                          capitalizacao: TextCapitalization.words,
                          prefixo: const Icon(Icons.person_outline, size: 20),
                          validador: (v) => (v == null || v.trim().length < 3)
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
                            if (d.length < 10) return 'Telefone incompleto';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CartaoSecao(
                    titulo: 'Interesse',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produto de interesse',
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
                          decoration: const InputDecoration(
                            hintText: 'Selecione o produto',
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                            ),
                          ),
                          items: estado.produtos
                              .map(
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
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _produto = v),
                        ),
                        const SizedBox(height: 16),
                        _SwitchLinha(
                          titulo: 'Contato feito hoje',
                          subtitulo: Fmt.data(_hoje ? DateTime.now() : _data),
                          valor: _hoje,
                          onChanged: (v) => setState(() => _hoje = v),
                        ),
                        if (!_hoje) ...[
                          const SizedBox(height: 12),
                          _BotaoData(
                            rotulo: 'Data do contato',
                            valor: Fmt.data(_data),
                            onTap: () => _escolherData(retorno: false),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _BotaoData(
                          rotulo: 'Data de retorno (follow-up)',
                          valor: _dataRetorno == null
                              ? 'Sem retorno agendado'
                              : Fmt.data(_dataRetorno!),
                          icone: Icons.event_repeat_outlined,
                          destaque: true,
                          onTap: () => _escolherData(retorno: true),
                          onLimpar: _dataRetorno == null
                              ? null
                              : () => setState(() => _dataRetorno = null),
                        ),
                        const SizedBox(height: 14),
                        CampoTexto(
                          rotulo: 'Observação',
                          controller: _obs,
                          dica: 'Ex.: pediu para ligar após as 14h',
                          maxLinhas: 3,
                          capitalizacao: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const RotuloBotao('CANCELAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: RotuloBotao(_editando ? 'SALVAR' : 'REGISTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchLinha extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _SwitchLinha({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: valor, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _BotaoData extends StatelessWidget {
  final String rotulo;
  final String valor;
  final IconData icone;
  final bool destaque;
  final VoidCallback onTap;
  final VoidCallback? onLimpar;

  const _BotaoData({
    required this.rotulo,
    required this.valor,
    required this.onTap,
    this.icone = Icons.calendar_today_outlined,
    this.destaque = false,
    this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? AppColors.accent : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 20, color: cor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cor,
                    ),
                  ),
                ],
              ),
            ),
            if (onLimpar != null)
              IconButton(
                onPressed: onLimpar,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
