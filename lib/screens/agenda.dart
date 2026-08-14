import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';

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
    final aniversarios = estado.clientes
        .where((c) => c.dataNascimento != null)
        .map((c) {
          final nascimento = c.dataNascimento!;
          var data = DateTime(hoje.year, nascimento.month, nascimento.day);
          if (data.isBefore(limiteHoje)) data = DateTime(hoje.year + 1, nascimento.month, nascimento.day);
          return _AgendaItem(nome: c.nome, detalhe: 'Aniversário em ${Fmt.data(data)}', data: data);
        })
        .where((item) => item.data.difference(limiteHoje).inDays <= 30)
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(titulo: 'Agenda', subtitulo: 'Pendências, retornos e aniversários', mostrarVoltar: false, mostrarAcoesGlobais: false),
          Expanded(child: ListView(
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
          const SizedBox(height: 16),
          _SecaoAgenda(
            titulo: 'Aniversários nos próximos 30 dias',
            icone: Icons.cake_outlined,
            itens: aniversarios,
            vazio: 'Nenhum aniversário informado para os próximos 30 dias.',
          ),
          ],
          )),
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
