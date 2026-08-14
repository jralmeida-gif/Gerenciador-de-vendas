import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

class TelaAjuda extends StatelessWidget {
  const TelaAjuda({super.key});

  static const _topicos = <({String titulo, String texto, IconData icone})>[
    (
      titulo: 'Como começar',
      texto: 'Cadastre produtos e, se necessário, convênios. Depois lance vendas, portabilidades e prospecções pelos respectivos menus. Os registros ficam separados por usuário.',
      icone: Icons.play_circle_outline,
    ),
    (
      titulo: 'Clientes e data de nascimento',
      texto: 'O cliente é consolidado pelo CPF. Na Ficha Consolidada de Clientes, você pode pesquisar o cadastro e tocar no ícone de calendário para informar ou corrigir a data de nascimento.',
      icone: Icons.badge_outlined,
    ),
    (
      titulo: 'Agenda e notificações',
      texto: 'A Agenda reúne pendências de hoje, retornos futuros e aniversários dos próximos 30 dias. Com as notificações autorizadas, o sistema também pode avisar sobre prazos e aniversários.',
      icone: Icons.notifications_none,
    ),
    (
      titulo: 'Metas mensais',
      texto: 'As metas individuais são cadastradas por mês e podem ser comparadas com o realizado nos relatórios e no painel de desempenho.',
      icone: Icons.flag_outlined,
    ),
    (
      titulo: 'Backups',
      texto: 'Exporte periodicamente os dados do seu usuário e mantenha o arquivo em local seguro. Cada usuário possui sua própria base e seus próprios backups.',
      icone: Icons.backup_outlined,
    ),
    (
      titulo: 'WhatsApp',
      texto: 'Nos menus de Vendas, Portabilidade e Prospecção, use o logo do WhatsApp para abrir uma mensagem com saudação contextual e o nome do cliente.',
      icone: Icons.chat_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(titulo: 'Ajuda', subtitulo: 'Orientações rápidas sobre o sistema', mostrarVoltar: false, mostrarAcoesGlobais: false),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: _topicos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final topico = _topicos[index];
                return Card(
                  child: ExpansionTile(
                    leading: Icon(topico.icone, color: AppColors.primary),
                    title: Text(topico.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [Text(topico.texto, style: const TextStyle(color: AppColors.textSecondary, height: 1.45))],
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
