import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/auth_client.dart';
import 'usuarios_admin.dart';
import '../services/backup_saver.dart';
import '../services/push_client.dart';
import '../services/dados_iniciais.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';
import 'campanhas.dart';
import 'metas_editar.dart';
import 'ajuda.dart';

/// Configurações: equipe, produtos, convênios, campanhas, backup e limpeza.
class _AvatarEnquadrado extends StatelessWidget {
  final Uint8List imageBytes;
  final double escala;
  final double deslocamentoX;
  final double deslocamentoY;
  const _AvatarEnquadrado({required this.imageBytes, required this.escala, required this.deslocamentoX, required this.deslocamentoY});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(deslocamentoX * 70, deslocamentoY * 70),
      child: Transform.scale(
        scale: escala,
        child: Image.memory(imageBytes, width: 190, height: 190, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.low),
      ),
    );
  }
}

class TelaConfiguracoes extends StatelessWidget {
  final AuthUser user;
  final VoidCallback? onLogout;
  const TelaConfiguracoes({super.key, required this.user, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(
            titulo: 'Configurações',
            subtitulo: 'Ajustes gerais do aplicativo',
            mostrarVoltar: true,
            voltarGlobal: true,
            mostrarAcoesGlobais: false,
            ajudaContextualTitulo: 'Configurações',
            ajudaContextualTexto: 'Administra perfil, foto, notificações, usuários, backup e ajuda.',
            ajudaContextualComoUsar: 'Escolha uma opção e salve as alterações. Administradores possuem ações adicionais de gerenciamento.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                CartaoSecao(
                  titulo: 'Meu perfil e sessão',
                  child: Column(
                    children: [
                      _Item(
                        icone: Icons.manage_accounts_outlined,
                        titulo: 'Editar perfil',
                        valor: 'Alias, foto, e-mail e telefone',
                        onTap: () => _editarPerfil(context, user.username),
                      ),
                      _Item(
                        icone: Icons.timer_outlined,
                        titulo: 'Bloqueio por inatividade',
                        valor: '${estado.idleTimeoutMinutes} minutos sem uso',
                        onTap: () => _editarTimeout(context),
                      ),
                      if (onLogout != null)
                        _ItemPerigo(
                          titulo: 'Sair do aplicativo',
                          subtitulo: 'Encerrar a sessão neste dispositivo',
                          onTap: () => _confirmarSaida(context),
                        ),
                    ],
                  ),
                ),
                CartaoSecao(
                  titulo: 'Orientação',
                  child: _Item(
                    icone: Icons.help_outline,
                    titulo: 'Ajuda e dicas',
                    valor: 'Como usar os principais recursos',
                    onTap: () {
                      final abrir = estado.onAbrirAjuda;
                      if (abrir != null) {
                        abrir();
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaAjuda()));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),
                if (user.isAdmin) ...[
                  CartaoSecao(
                    titulo: 'Administração',
                    child: _Item(
                      icone: Icons.admin_panel_settings_outlined,
                      titulo: 'Usuários do sistema',
                      valor: 'Cadastrar, ativar e definir perfis',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaUsuariosAdmin())),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                CartaoSecao(
                  titulo: 'Metas e campanhas',
                  child: Column(
                    children: [
                      _Item(
                        icone: Icons.flag_outlined,
                        titulo: 'Metas do mês',
                        valor: '${estado.produtos.length} produto(s)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaMetasEditar(),
                          ),
                        ),
                      ),
                      _Item(
                        icone: Icons.campaign_outlined,
                        titulo: 'Campanhas',
                        valor: '${estado.campanhas.length} cadastrada(s)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaCampanhas(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CartaoSecao(
                  titulo: 'Cadastros',
                  child: Column(
                    children: [
                      _Item(
                        icone: Icons.inventory_2_outlined,
                        titulo: 'Produtos',
                        valor: '${estado.produtos.length} item(ns)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaProdutos(),
                          ),
                        ),
                      ),
                      _Item(
                        icone: Icons.account_balance_outlined,
                        titulo: 'Convênios',
                        valor: '${estado.convenios.length} item(ns)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TelaConvenios(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CartaoSecao(
                  titulo: 'Backup dos dados',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'O backup automático fica dentro do aplicativo e pode ser restaurado pela lista interna. Ele pode ser perdido se os dados do PWA forem apagados. Para proteção adicional, use também Exportar para Arquivos e guarde uma cópia externa.'
                                '${estado.ultimoBackup != null ? '\n\nÚltimo backup: ${Fmt.data(estado.ultimoBackup!)}' : ''}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _criarBackupInterno(context),
                              icon: const Icon(Icons.cloud_done_outlined, size: 19),
                              label: const RotuloBotao('CRIAR BACKUP AUTOMÁTICO DO APP'),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _exportar(context),
                                  icon: const Icon(Icons.folder_outlined, size: 19),
                                  label: const RotuloBotao('EXPORTAR PARA ARQUIVOS'),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _importar(context),
                                  icon: const Icon(Icons.restore_outlined, size: 19),
                                  label: const RotuloBotao('IMPORTAR'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CartaoSecao(
                  titulo: 'Notificações de prazo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receba avisos de portabilidades pendentes e retornos de prospecção, mesmo quando o app estiver fechado. O navegador solicitará sua autorização.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await PushClient.enable();
                            if (ok) {
                              await estado.sincronizarPrazosPush();
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Notificações ativadas neste dispositivo.'
                                      : 'A permissão está bloqueada. No iPhone, ative as notificações em Ajustes → Notificações → Gestor de Vendas ou Safari e tente novamente.',
                                ),
                                backgroundColor: ok
                                    ? AppColors.success
                                    : AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const RotuloBotao('ATIVAR NOTIFICAÇÕES'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CartaoSecao(
                  titulo: 'Zona de risco',
                  child: Column(
                    children: [
                      _ItemPerigo(
                        titulo: 'Limpar base de Vendas',
                        subtitulo: '${estado.vendas.length} registro(s)',
                        onTap: () => _limpar(context, 'vendas', 'Vendas'),
                      ),
                      _ItemPerigo(
                        titulo: 'Limpar base de Portabilidade',
                        subtitulo:
                            '${estado.portabilidades.length} registro(s)',
                        onTap: () =>
                            _limpar(context, 'portabilidades', 'Portabilidade'),
                      ),
                      _ItemPerigo(
                        titulo: 'Limpar base de Prospecção',
                        subtitulo: '${estado.prospeccoes.length} registro(s)',
                        onTap: () =>
                            _limpar(context, 'prospeccoes', 'Prospecção'),
                      ),
                      _ItemPerigo(
                        titulo: 'Apagar TUDO',
                        subtitulo: 'Restaura o app ao estado inicial',
                        onTap: () => _limpar(context, 'tudo', 'todos os dados'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Gestor de Vendas · v3.1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- Ações -------------------

  Future<void> _confirmarSaida(BuildContext context) async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do aplicativo?'),
        content: const Text('A sessão será encerrada neste dispositivo. Seus dados sincronizados permanecerão separados na sua conta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar no app')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (sair == true && context.mounted) onLogout?.call();
  }

  static Future<void> _editarAvatar(BuildContext context) async {
    final estado = context.read<AppState>();
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res == null || res.files.isEmpty || !context.mounted) return;
    final bytes = res.files.first.bytes;
    if (bytes == null || bytes.length > 2 * 1024 * 1024) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha uma imagem de até 2 MB.')));
      return;
    }
    final encoded = 'data:image/${res.files.first.extension ?? 'jpeg'};base64,${base64Encode(bytes)}';
    var escala = estado.avatarScale;
    var escalaInicial = escala;
    var deslocamentoX = estado.avatarOffsetX;
    var deslocamentoY = estado.avatarOffsetY;
    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Ajustar enquadramento da foto'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onScaleStart: (_) => escalaInicial = escala,
                  onScaleUpdate: (details) => setDialog(() {
                    escala = (escalaInicial * details.scale).clamp(1.0, 3.0);
                    deslocamentoX = (deslocamentoX + details.focalPointDelta.dx / 150).clamp(-1.0, 1.0);
                    deslocamentoY = (deslocamentoY + details.focalPointDelta.dy / 150).clamp(-1.0, 1.0);
                  }),
                  child: ClipOval(
                    child: Container(
                      width: 190,
                      height: 190,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: _AvatarEnquadrado(
                        imageBytes: bytes,
                        escala: escala,
                        deslocamentoX: deslocamentoX,
                        deslocamentoY: deslocamentoY,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Mova a foto e use dois dedos para aproximar ou afastar.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (salvo == true && context.mounted) {
      await estado.salvarAvatarData(encoded);
      await estado.salvarAvatarEnquadramento(escala: escala, deslocamentoX: deslocamentoX, deslocamentoY: deslocamentoY);
    }
  }

  static Future<void> _editarTimeout(BuildContext context) async {
    final estado = context.read<AppState>();
    final escolha = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Bloqueio por inatividade'),
        children: [15, 30, 60].map((minutos) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, minutos),
          child: Text('$minutos minutos'),
        )).toList(),
      ),
    );
    if (escolha != null) await estado.salvarIdleTimeoutMinutes(escolha);
  }

  static Future<void> _editarPerfil(BuildContext context, String email) async {
    final estado = context.read<AppState>();
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Editar meu perfil')),
            ListTile(leading: const Icon(Icons.person_outline), title: const Text('Alias'), subtitle: Text(estado.nomeUsuario), onTap: () => Navigator.pop(ctx, 'alias')),
            ListTile(leading: const Icon(Icons.account_circle_outlined), title: const Text('Foto de perfil'), subtitle: Text(estado.avatarData.isEmpty ? 'Adicionar foto' : 'Alterar foto'), onTap: () => Navigator.pop(ctx, 'foto')),
            ListTile(leading: const Icon(Icons.email_outlined), title: const Text('E-mail de acesso'), subtitle: Text(email)),
            ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Telefone'), subtitle: Text(estado.telefoneUsuario.isEmpty ? 'Opcional — adicionar' : Fmt.telefone(estado.telefoneUsuario), onTap: () => Navigator.pop(ctx, 'telefone')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || escolha == null) return;
    if (escolha == 'alias') await _editarNome(context);
    if (escolha == 'foto') await _editarAvatar(context);
    if (escolha == 'telefone') await _editarTelefone(context);
  }

  static Future<void> _editarTelefone(BuildContext context) async {
    final estado = context.read<AppState>();
    final ctrl = TextEditingController(text: estado.telefoneUsuario);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Telefone do perfil'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone opcional')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) await estado.salvarTelefoneUsuario(Fmt.somenteDigitos(ctrl.text));
  }

  static Future<void> _editarNome(BuildContext context) async {
    final estado = context.read<AppState>();
    final ctrl = TextEditingController(text: estado.nomeUsuario);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome ou alias exibido'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Seu nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await estado.salvarNomeUsuario(ctrl.text.trim());
    }
  }

  static Future<void> _exportar(BuildContext context) async {
    final estado = context.read<AppState>();
    final conteudo = estado.exportarBackup();
    final bytes = Uint8List.fromList(utf8.encode(conteudo));
    final agora = DateTime.now();
    String dois(int valor) => valor.toString().padLeft(2, '0');
    final nome =
        'backup-gestor-vendas-${agora.year}-${dois(agora.month)}-${dois(agora.day)}-${dois(agora.hour)}h${dois(agora.minute)}m${dois(agora.second)}s.json';

    final iniciar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.save_alt, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Salvar backup'),
          ],
        ),
        content: Text(
          'Vamos abrir o salvamento de arquivos do aparelho para você escolher onde guardar a cópia externa.\n\n'
          'Nome do arquivo:\n$nome\n\n'
          'Escolha Arquivos, Downloads, iCloud Drive, Google Drive ou outra pasta segura.',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Escolher onde salvar'),
          ),
        ],
      ),
    );
    if (iniciar != true || !context.mounted) return;

    final salvo = await BackupSaver.save(bytes, nome);
    if (!salvo) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o salvamento automático. Escolha novamente o local ou tente pelo Safari.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await estado.marcarBackup();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup preparado'),
        content: Text(
          'O arquivo "$nome" foi salvo ou encaminhado ao seletor de arquivos do aparelho. '
          'Guarde-o em um local seguro. Depois, você poderá restaurá-lo pela opção IMPORTAR.',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  static Future<void> _criarBackupInterno(BuildContext context) async {
    final estado = context.read<AppState>();
    await estado.criarBackupInterno();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup automático criado e armazenado no app.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> _importar(BuildContext context) async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Restaurar backup'), subtitle: Text('Escolha a origem do arquivo')),
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined),
              title: const Text('Restaurar backup do app'),
              subtitle: const Text('Escolher uma cópia automática interna'),
              onTap: () => Navigator.pop(ctx, 'interno'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Restaurar de outro local'),
              subtitle: const Text('Abrir Arquivos, Downloads ou outra pasta'),
              onTap: () => Navigator.pop(ctx, 'externo'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || escolha == null) return;
    if (escolha == 'interno') {
      await _importarInterno(context);
    } else {
      await _importarExterno(context);
    }
  }

  static Future<void> _importarInterno(BuildContext context) async {
    final estado = context.read<AppState>();
    final backups = estado.backupsInternos;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ainda não existe backup automático interno.')));
      return;
    }
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Backups automáticos do app')),
            ...backups.map((backup) {
              final data = DateTime.tryParse(backup['geradoEm'] as String? ?? '');
              final tamanho = (((backup['tamanho'] as num?)?.toDouble() ?? 0) / 1024).toStringAsFixed(0);
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(data == null ? 'Backup automático' : Fmt.dataHora(data)),
                subtitle: Text('$tamanho KB'),
                trailing: const Icon(Icons.restore),
                onTap: () => Navigator.pop(ctx, backup['id'] as String),
              );
            }),
          ],
        ),
      ),
    );
    if (!context.mounted || id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup interno?'),
        content: const Text('Os dados atuais serão substituídos. Recomendamos criar um backup atual antes de continuar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await estado.restaurarBackupInterno(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup interno restaurado com sucesso.'), backgroundColor: AppColors.success));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível restaurar este backup.'), backgroundColor: AppColors.danger));
    }
  }

  static Future<void> _importarExterno(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: const Text(
          'Os dados atuais serão substituídos pelos do arquivo. '
          'Recomendamos exportar um backup antes. Deseja continuar?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirma != true || !context.mounted) return;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (res == null || res.files.isEmpty || !context.mounted) return;

    final bytes = res.files.first.bytes;
    if (bytes == null) return;

    try {
      final texto = utf8.decode(bytes);
      await context.read<AppState>().importarBackup(texto);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restaurado com sucesso.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo inválido ou corrompido.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> _limpar(
    BuildContext context,
    String chave,
    String rotulo,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Limpar $rotulo'),
        content: Text(
          'Esta ação apaga permanentemente $rotulo deste aparelho e não pode ser desfeita.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AppState>().limparBase(chave);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$rotulo removido(s).'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final VoidCallback onTap;
  const _Item({
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icone, size: 20, color: AppColors.primary),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPerigo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  const _ItemPerigo({
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            const Icon(
              Icons.delete_sweep_outlined,
              size: 20,
              color: AppColors.danger,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class TelaProdutos extends StatelessWidget {
  const TelaProdutos({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final produtos = estado.produtos;

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Produtos',
            subtitulo: '${produtos.length} produto(s) cadastrado(s)',
            mostrarVoltar: true,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: produtos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = produtos[i];
                final meta = estado.metaDoProduto(p.nome);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nome,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Etiqueta(
                                  texto: p.formato,
                                  cor: p.ehQuantidade
                                      ? AppColors.primaryLight
                                      : AppColors.accent,
                                ),
                                if (meta > 0) ...[
                                  const SizedBox(width: 6),
                                  Etiqueta(
                                    texto:
                                        'Meta ${Fmt.valorPorFormato(meta, p.formato)}',
                                    cor: AppColors.success,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _form(context, p),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        color: AppColors.textSecondary,
                      ),
                      IconButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Excluir produto'),
                              content: Text(
                                'Remover "${p.nome}"? Vendas já lançadas não são apagadas.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.danger,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await context.read<AppState>().excluirProduto(
                              p.nome,
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 19),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, null),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static Future<void> _form(BuildContext context, Produto? p) async {
    final nome = TextEditingController(text: p?.nome ?? '');
    String formato = p?.formato ?? 'Valor';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(p == null ? 'Novo produto' : 'Editar produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                autofocus: p == null,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Nome do produto'),
              ),
              const SizedBox(height: 14),
              Row(
                children: DadosIniciais.formatos.map((f) {
                  final sel = formato == f;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) => setLocal(() => formato = f),
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || nome.text.trim().isEmpty || !context.mounted) return;
    final estado = context.read<AppState>();
    if (p != null && p.nome != nome.text.trim()) {
      await estado.excluirProduto(p.nome);
    }
    await estado.salvarProduto(
      Produto(nome: nome.text.trim(), formato: formato),
    );
  }
}

// ---------------------------------------------------------------------------

class TelaConvenios extends StatelessWidget {
  const TelaConvenios({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final convenios = estado.convenios;

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Convênios',
            subtitulo: '${convenios.length} convênio(s) cadastrado(s)',
            mostrarVoltar: true,
          ),
          Expanded(
            child: convenios.isEmpty
                ? const EstadoVazio(
                    icone: Icons.account_balance_outlined,
                    titulo: 'Nenhum convênio',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    itemCount: convenios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = convenios[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nome,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Etiqueta(
                                    texto: 'Cód. ${c.codigo}',
                                    cor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _form(context, c),
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              color: AppColors.textSecondary,
                            ),
                            IconButton(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir convênio'),
                                    content: Text('Remover "${c.nome}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  await context
                                      .read<AppState>()
                                      .excluirConvenio(c.nome);
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 19),
                              color: AppColors.danger,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, null),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static Future<void> _form(BuildContext context, Convenio? c) async {
    final nome = TextEditingController(text: c?.nome ?? '');
    final codigo = TextEditingController(text: c?.codigo ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c == null ? 'Novo convênio' : 'Editar convênio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              autofocus: c == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Nome do convênio'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codigo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Código'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true || nome.text.trim().isEmpty || !context.mounted) return;
    final estado = context.read<AppState>();
    if (c != null && c.nome != nome.text.trim()) {
      await estado.excluirConvenio(c.nome);
    }
    await estado.salvarConvenio(
      Convenio(nome: nome.text.trim(), codigo: codigo.text.trim()),
    );
  }
}
