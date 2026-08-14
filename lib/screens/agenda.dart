import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class TelaAgenda extends StatelessWidget {
  const TelaAgenda({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final hoje = DateTime.now();
    final limiteHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final retornos = estado.prospeccoes
        .where((p) => !p.concluida && p.dataRetorno != null)
        .map((p) => _AgendaItem(nome: p.nome, detalhe: 'Retorno em ${Fmt.data(p.dataRetorno!)}', data: p.dataRetorno!))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final portabilidades = estado.portPendentes
        .map((p) => _AgendaItem(nome: p.nome, detalhe: 'Portabilidade pendente', data: p.data))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SecaoAgenda(
            titulo: 'Pendências de hoje',
            icone: Icons.today_outlined,
            itens: [
              ...retornos.where((item) => !item.data.isAfter(limiteHoje)),
              ...portabilidades,
            ],
            vazio: 'Nenhuma pendência para hoje.',
          ),
          const SizedBox(height: 16),
          _SecaoAgenda(
            titulo: 'Próximos retornos',
            icone: Icons.event_available_outlined,
            itens: retornos.where((item) => item.data.isAfter(limiteHoje)).toList(),
            vazio: 'Nenhum retorno futuro cadastrado.',
          ),
        ],
      ),
    );
  }
}

class _AgendaItem {
  final String nome;
  final String detalhe;
  final DateTime data;
  const _AgendaItem({required this.nome, required this.detalhe, required this.data});
}

class _SecaoAgenda extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final List<_AgendaItem> itens;
  final String vazio;
  const _SecaoAgenda({required this.titulo, required this.icone, required this.itens, required this.vazio});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icone, color: AppColors.primary), const SizedBox(width: 8), Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))]),
            const SizedBox(height: 10),
            if (itens.isEmpty) Text(vazio, style: const TextStyle(color: AppColors.textSecondary))
            else ...itens.map((item) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline), title: Text(item.nome), subtitle: Text(item.detalhe))),
          ],
        ),
      ),
    );
  }
}
