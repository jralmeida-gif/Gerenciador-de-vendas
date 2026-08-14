import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/whatsapp.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';
import 'portabilidade_confirmar.dart';
import 'portabilidade_form.dart';

class TelaPortabilidadeLista extends StatefulWidget {
  const TelaPortabilidadeLista({super.key});

  @override
  State<TelaPortabilidadeLista> createState() => _TelaPortabilidadeListaState();
}

class _TelaPortabilidadeListaState extends State<TelaPortabilidadeLista>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final pendentes = estado.portPendentes;
    final confirmadas = estado.portConfirmadas;

    final totalPend = pendentes.fold<double>(0, (s, p) => s + p.saldoDevedor);
    final totalConf = confirmadas.fold<double>(0, (s, p) => s + p.saldoDevedor);

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Portabilidade',
            subtitulo: 'Consignado · pedidos e confirmações',
            mostrarVoltar: false,
            rodape: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(height: 38, text: 'Pendentes (${pendentes.length})'),
                  Tab(height: 38, text: 'Confirmadas (${confirmadas.length})'),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _tab.index == 0
                      ? Icons.hourglass_empty
                      : Icons.verified_outlined,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Saldo total: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  Fmt.moeda(_tab.index == 0 ? totalPend : totalConf),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _Lista(itens: pendentes, pendente: true),
                _Lista(itens: confirmadas, pendente: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaPortabilidadeForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova portabilidade',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<Portabilidade> itens;
  final bool pendente;
  const _Lista({required this.itens, required this.pendente});

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return EstadoVazio(
        icone: pendente
            ? Icons.pending_actions_outlined
            : Icons.verified_outlined,
        titulo: pendente
            ? 'Nenhum pedido pendente'
            : 'Nenhuma portabilidade confirmada',
        mensagem: pendente
            ? 'Cadastre um pedido de portabilidade para acompanhar.'
            : 'Ao confirmar um pedido pendente, ele aparecerá aqui.',
        acao: pendente
            ? ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaPortabilidadeForm(),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const RotuloBotao('NOVO PEDIDO'),
              )
            : null,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CartaoPort(port: itens[i]),
    );
  }
}

class _CartaoPort extends StatelessWidget {
  final Portabilidade port;
  const _CartaoPort({required this.port});

  @override
  Widget build(BuildContext context) {
    final cor = port.confirmado ? AppColors.success : AppColors.accent;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _acoes(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 74,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            port.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Etiqueta(
                          texto: port.confirmado ? 'CONFIRMADA' : 'PENDENTE',
                          cor: cor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Fmt.cpf(port.cpf),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Etiqueta(texto: port.convenio, cor: AppColors.primary),
                        const Spacer(),
                        Text(
                          Fmt.moeda(port.saldoDevedor),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${port.qtdPrestacoes}x ${Fmt.moeda(port.valorPrestacao)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          port.confirmado && port.numeroContrato.isNotEmpty
                              ? 'Contrato ${port.numeroContrato}'
                              : Fmt.data(port.data),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _acoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              title: Text(
                port.nome,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${port.convenio} · ${Fmt.telefone(port.telefone)}\n'
                'Saldo ${Fmt.moeda(port.saldoDevedor)} · ${port.qtdPrestacoes}x ${Fmt.moeda(port.valorPrestacao)}'
                '${port.observacoes.isEmpty ? '' : '\n${port.observacoes}'}',
                style: const TextStyle(height: 1.5),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Image.asset('assets/icon/whatsapp_logo.png', width: 22, height: 22),
              title: const Text('Enviar mensagem pelo WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await WhatsApp.abrir(telefone: port.telefone, mensagem: WhatsApp.saudacao(port.nome));
                if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone inválido para abrir o WhatsApp.')));
              },
            ),
            if (!port.confirmado)
              ListTile(
                leading: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.success,
                ),
                title: const Text('Confirmar portabilidade'),
                subtitle: const Text(
                  'Informar nº do contrato e valores finais',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaPortabilidadeConfirmar(port: port),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Editar dados'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TelaPortabilidadeForm(port: port),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.cancel_outlined,
                color: AppColors.danger,
              ),
              title: Text(
                port.confirmado ? 'Excluir registro' : 'Cancelar pedido',
                style: const TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(
                      port.confirmado
                          ? 'Excluir registro?'
                          : 'Cancelar pedido?',
                    ),
                    content: const Text('Esta ação não pode ser desfeita.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Voltar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('CONFIRMAR'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AppState>().excluirPortabilidade(port.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
