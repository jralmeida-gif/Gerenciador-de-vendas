import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

/// Confirmação de portabilidade — equivalente ao formulário VBA frmPortEdit.
class TelaPortabilidadeConfirmar extends StatefulWidget {
  final Portabilidade port;
  const TelaPortabilidadeConfirmar({super.key, required this.port});

  @override
  State<TelaPortabilidadeConfirmar> createState() =>
      _TelaPortabilidadeConfirmarState();
}

class _TelaPortabilidadeConfirmarState
    extends State<TelaPortabilidadeConfirmar> {
  final _contrato = TextEditingController();
  late final TextEditingController _saldo;
  late final TextEditingController _prestacao;
  late final TextEditingController _qtd;
  DateTime _dataConf = DateTime.now();

  @override
  void initState() {
    super.initState();
    _saldo = TextEditingController(text: Fmt.decimal(widget.port.saldoDevedor));
    _prestacao = TextEditingController(
      text: Fmt.decimal(widget.port.valorPrestacao),
    );
    _qtd = TextEditingController(text: '${widget.port.qtdPrestacoes}');
  }

  @override
  void dispose() {
    _contrato.dispose();
    _saldo.dispose();
    _prestacao.dispose();
    _qtd.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataConf,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d != null) setState(() => _dataConf = d);
  }

  Future<void> _confirmar() async {
    final contratoDigitos = Fmt.somenteDigitos(_contrato.text);
    if (contratoDigitos.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o número do contrato gerado pela instituição.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final estado = context.read<AppState>();
    final atualizada = widget.port.copyWith(
      confirmado: true,
      numeroContrato: Fmt.contrato(_contrato.text),
      dataConfirmacao: _dataConf,
      saldoDevedor: Fmt.parseNumero(_saldo.text),
      valorPrestacao: Fmt.parseNumero(_prestacao.text),
      qtdPrestacoes:
          int.tryParse(Fmt.somenteDigitos(_qtd.text)) ??
          widget.port.qtdPrestacoes,
    );
    await estado.salvarPortabilidade(atualizada);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Portabilidade confirmada com sucesso!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.port;
    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(
            titulo: 'Confirmar Portabilidade',
            subtitulo: 'Informe os dados finais do contrato',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.nome,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${Fmt.cpf(p.cpf)}  ·  ${p.convenio}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pedido em ${Fmt.data(p.data)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CartaoSecao(
                  titulo: 'Dados da confirmação',
                  child: Column(
                    children: [
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
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _escolherData,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data da confirmação',
                            prefixIcon: Icon(
                              Icons.event_available_outlined,
                              size: 19,
                            ),
                          ),
                          child: Text(
                            Fmt.data(_dataConf),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CampoTexto(
                        rotulo: 'Saldo devedor final',
                        controller: _saldo,
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
                              rotulo: 'Valor prestação',
                              controller: _prestacao,
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
                              teclado: TextInputType.number,
                              formatadores: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 17,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Os valores vêm preenchidos com o cadastro inicial. Ajuste se houver divergência no contrato final.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        onPressed: _confirmar,
                        icon: const Icon(Icons.verified, size: 19),
                        label: const RotuloBotao('CONFIRMAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const RotuloBotao('VOLTAR'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
