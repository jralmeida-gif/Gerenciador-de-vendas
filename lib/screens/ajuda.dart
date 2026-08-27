import 'package:flutter/material.dart';

import '../data/ajuda_conteudo.dart';
import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

class TelaAjuda extends StatefulWidget {
  const TelaAjuda({super.key});

  @override
  State<TelaAjuda> createState() => _TelaAjudaState();
}

class _TelaAjudaState extends State<TelaAjuda> {
  final _busca = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  List<ItemFaq> _itensFiltrados(CategoriaAjuda categoria) {
    if (_filtro.trim().isEmpty) return categoria.itens;
    final termo = _filtro.trim().toLowerCase();
    return categoria.itens.where((item) => '${item.pergunta} ${item.resposta}'.toLowerCase().contains(termo)).toList();
  }

  List<CategoriaAjuda> get _categoriasVisiveis => categoriasAjuda.where((categoria) => _itensFiltrados(categoria).isNotEmpty).toList();

  List<RecursoAjuda> get _recursosVisiveis {
    final termo = _filtro.trim().toLowerCase();
    if (termo.isEmpty) return recursosAjuda;
    return recursosAjuda.where((recurso) {
      final texto = [
        recurso.nome,
        recurso.descricao ?? '',
        recurso.explicacao,
        ...recurso.passos,
      ].join(' ').toLowerCase();
      return texto.contains(termo);
    }).toList();
  }

  void _abrirRecursos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TelaRecursosAjuda()),
    );
  }

  void _abrirRecurso(BuildContext context, RecursoAjuda recurso) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TelaRecursoAjuda(recurso: recurso)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temBusca = _filtro.trim().isNotEmpty;
    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(titulo: 'Central de Ajuda', subtitulo: 'FAQ, dicas e solução de problemas', mostrarVoltar: true, voltarGlobal: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TextField(
                  controller: _busca,
                  onChanged: (value) => setState(() => _filtro = value),
                  decoration: InputDecoration(
                    hintText: 'O que você precisa saber?',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busca.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _busca.clear(); setState(() => _filtro = ''); }),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                if (!temBusca) ...[
                  Row(children: [
                    Expanded(child: _AtalhoAjuda(titulo: 'Primeiros passos', icone: Icons.play_circle_outline, onTap: () => _abrirCategoria(context, categoriasAjuda.first))),
                    const SizedBox(width: 10),
                    Expanded(child: _AtalhoAjuda(titulo: 'Problemas comuns', icone: Icons.build_outlined, onTap: () => _abrirProblemas(context))),
                  ]),
                  const SizedBox(height: 10),
                  _AtalhoAjuda(titulo: 'Recursos do sistema', icone: Icons.menu_book_outlined, onTap: () => _abrirRecursos(context)),
                  const SizedBox(height: 18),
                  const Text('Recursos do sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Veja o que o sistema oferece e abra o passo a passo de cada recurso.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ..._recursosVisiveis.map((recurso) => _RecursoCard(recurso: recurso, onTap: () => _abrirRecurso(context, recurso))),
                  const SizedBox(height: 8),
                  const Text('Perguntas frequentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Escolha uma categoria para encontrar orientações rápidas.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                ],
                if (temBusca && _recursosVisiveis.isNotEmpty) ...[
                  const Text('Recursos do sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._recursosVisiveis.map((recurso) => _RecursoCard(recurso: recurso, onTap: () => _abrirRecurso(context, recurso))),
                  const SizedBox(height: 8),
                ],
                if (temBusca && _categoriasVisiveis.isNotEmpty) ...[
                  const Text('Perguntas frequentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                ],
                if (temBusca && _categoriasVisiveis.isEmpty && _recursosVisiveis.isEmpty) const EstadoVazio(icone: Icons.search_off, titulo: 'Nenhuma resposta encontrada', mensagem: 'Tente outra palavra ou escolha uma categoria.'),
                ..._categoriasVisiveis.map((categoria) => _CategoriaCard(categoria: categoria, filtro: _filtro)),
                if (!temBusca) ...[
                  const SizedBox(height: 18),
                  const Text('Solução de problemas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...problemasAjuda.map((item) => _FaqTile(item: item)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirCategoria(BuildContext context, CategoriaAjuda categoria) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), shrinkWrap: true, children: [
      Text(categoria.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(categoria.descricao, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      ...categoria.itens.map((item) => _FaqTile(item: item)),
    ])),
  );

  void _abrirProblemas(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), shrinkWrap: true, children: [
      const Text('Solução de problemas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      ...problemasAjuda.map((item) => _FaqTile(item: item)),
    ])),
  );
}

class _CategoriaCard extends StatelessWidget {
  final CategoriaAjuda categoria;
  final String filtro;
  const _CategoriaCard({required this.categoria, required this.filtro});

  @override
  Widget build(BuildContext context) {
    final itens = filtro.trim().isEmpty ? categoria.itens : categoria.itens.where((item) => '${item.pergunta} ${item.resposta}'.toLowerCase().contains(filtro.trim().toLowerCase())).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(categoria.icone, color: AppColors.primary),
        title: Text(categoria.titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(categoria.descricao),
        children: itens.map((item) => _FaqTile(item: item)).toList(),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final ItemFaq item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    color: const Color(0xFFF7F9FC),
    child: ExpansionTile(
      leading: Icon(item.icone, size: 21, color: AppColors.primary),
      title: Text(item.pergunta, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      children: [Text(item.resposta, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45))],
    ),
  );
}

class _AtalhoAjuda extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final VoidCallback onTap;
  const _AtalhoAjuda({required this.titulo, required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13), child: Column(children: [Icon(icone, color: AppColors.primary, size: 26), const SizedBox(height: 6), Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))])),
    ),
  );
}

class TelaRecursosAjuda extends StatelessWidget {
  const TelaRecursosAjuda({super.key});

  void _abrirRecurso(BuildContext context, RecursoAjuda recurso) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TelaRecursoAjuda(recurso: recurso)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(
            titulo: 'Recursos do sistema',
            subtitulo: 'Veja o que o app oferece e como usar',
            mostrarVoltar: true,
            voltarGlobal: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Toque em um recurso para ver um passo a passo simples. Os recursos estão organizados em ordem alfabética.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...recursosAjuda.map(
                  (recurso) => _RecursoCard(
                    recurso: recurso,
                    onTap: () => _abrirRecurso(context, recurso),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecursoCard extends StatelessWidget {
  final RecursoAjuda recurso;
  final VoidCallback onTap;

  const _RecursoCard({required this.recurso, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          foregroundColor: AppColors.primary,
          child: Icon(recurso.icone, size: 21),
        ),
        title: Text(
          recurso.nome,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: recurso.descricao == null
            ? null
            : Text(
                recurso.descricao!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class TelaRecursoAjuda extends StatelessWidget {
  final RecursoAjuda recurso;

  const TelaRecursoAjuda({super.key, required this.recurso});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: recurso.nome,
            subtitulo: 'Passo a passo',
            mostrarVoltar: true,
            voltarGlobal: true,
            ajudaContextualTitulo: recurso.nome,
            ajudaContextualTexto: recurso.explicacao,
            ajudaContextualComoUsar:
                'Siga os passos abaixo e use a seta do cabeçalho para voltar aos recursos.',
            ajudaContextualAtencao: recurso.atencao,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                CartaoSecao(
                  titulo: 'O que este recurso faz',
                  child: Text(
                    recurso.explicacao,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CartaoSecao(
                  titulo: 'Como usar',
                  child: Column(
                    children: [
                      for (var i = 0; i < recurso.passos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  recurso.passos[i],
                                  style: const TextStyle(
                                    fontSize: 13.5,
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
                if (recurso.atencao != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            recurso.atencao!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
