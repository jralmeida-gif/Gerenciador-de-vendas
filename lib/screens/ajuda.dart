import 'package:flutter/material.dart';

import '../data/ajuda_conteudo.dart';
import '../services/auth_client.dart';
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
  bool _exibindoRecursos = false;
  RecursoAjuda? _recursoAberto;
  CategoriaAjuda? _categoriaAberta;
  bool _problemasAbertos = false;
  bool _feedbackAberto = false;

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

  void _abrirRecursos() {
    setState(() {
      _exibindoRecursos = true;
      _recursoAberto = null;
      _categoriaAberta = null;
      _problemasAbertos = false;
      _feedbackAberto = false;
    });
  }

  void _abrirCategoria(CategoriaAjuda categoria) {
    setState(() {
      _categoriaAberta = categoria;
      _exibindoRecursos = false;
      _recursoAberto = null;
      _problemasAbertos = false;
      _feedbackAberto = false;
    });
  }

  void _abrirProblemas() {
    setState(() {
      _problemasAbertos = true;
      _exibindoRecursos = false;
      _recursoAberto = null;
      _categoriaAberta = null;
      _feedbackAberto = false;
    });
  }

  void _abrirFeedback() {
    setState(() {
      _feedbackAberto = true;
      _exibindoRecursos = false;
      _recursoAberto = null;
      _categoriaAberta = null;
      _problemasAbertos = false;
    });
  }

  void _abrirRecurso(RecursoAjuda recurso) {
    setState(() {
      _exibindoRecursos = false;
      _recursoAberto = recurso;
      _categoriaAberta = null;
      _problemasAbertos = false;
      _feedbackAberto = false;
    });
  }

  void _voltarParaInicio() {
    setState(() {
      _exibindoRecursos = false;
      _recursoAberto = null;
      _categoriaAberta = null;
      _problemasAbertos = false;
      _feedbackAberto = false;
    });
  }

  void _voltarParaRecursos() {
    setState(() {
      _exibindoRecursos = true;
      _recursoAberto = null;
      _categoriaAberta = null;
      _problemasAbertos = false;
      _feedbackAberto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_feedbackAberto) {
      return _FeedbackAjudaConteudo(onVoltar: _voltarParaInicio);
    }
    if (_recursoAberto != null) {
      return _RecursoAjudaConteudo(
        recurso: _recursoAberto!,
        onVoltar: _voltarParaRecursos,
      );
    }
    if (_categoriaAberta != null) {
      return _SecaoAjudaConteudo(
        categoria: _categoriaAberta!,
        onVoltar: _voltarParaInicio,
      );
    }
    if (_problemasAbertos) {
      return _ProblemasAjudaConteudo(onVoltar: _voltarParaInicio);
    }
    if (_exibindoRecursos) {
      return _RecursosAjudaConteudo(
        onVoltar: _voltarParaInicio,
        onAbrirRecurso: _abrirRecurso,
      );
    }
    return _buildInicio(context);
  }

  Widget _buildInicio(BuildContext context) {
    final temBusca = _filtro.trim().isNotEmpty;
    return Scaffold(
      body: Column(
        children: [
          const HeaderCurvo(titulo: 'Central de Ajuda', subtitulo: 'FAQ, dicas e solução de problemas', mostrarVoltar: false),
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
                    Expanded(child: _AtalhoAjuda(titulo: 'Primeiros passos', icone: Icons.play_circle_outline, onTap: () => _abrirCategoria(categoriasAjuda.first))),
                    const SizedBox(width: 10),
                    Expanded(child: _AtalhoAjuda(titulo: 'Problemas comuns', icone: Icons.build_outlined, onTap: () => _abrirProblemas())),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _AtalhoAjuda(titulo: 'Recursos do sistema', icone: Icons.menu_book_outlined, onTap: () => _abrirRecursos())),
                    const SizedBox(width: 10),
                    Expanded(child: _AtalhoAjuda(titulo: 'Sugestões e falhas', icone: Icons.feedback_outlined, onTap: () => _abrirFeedback())),
                  ]),
                  const SizedBox(height: 18),
                  const Text('Escolha uma opção para continuar.', style: TextStyle(color: AppColors.textSecondary)),
                ],
                if (temBusca && _recursosVisiveis.isNotEmpty) ...[
                  const Text('Recursos do sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._recursosVisiveis.map((recurso) => _RecursoCard(recurso: recurso, onTap: () => _abrirRecurso(recurso))),
                  const SizedBox(height: 8),
                ],
                if (temBusca && _categoriasVisiveis.isNotEmpty) ...[
                  const Text('Perguntas frequentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                ],
                if (temBusca && _categoriasVisiveis.isEmpty && _recursosVisiveis.isEmpty) const EstadoVazio(icone: Icons.search_off, titulo: 'Nenhuma resposta encontrada', mensagem: 'Tente outra palavra ou escolha uma categoria.'),
                if (temBusca) ..._categoriasVisiveis.map((categoria) => _CategoriaCard(categoria: categoria, filtro: _filtro)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

class _RecursoAjudaConteudo extends StatelessWidget {
  final RecursoAjuda recurso;
  final VoidCallback onVoltar;

  const _RecursoAjudaConteudo({
    required this.recurso,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: recurso.nome,
            subtitulo: 'Passo a passo',
            mostrarVoltar: true,
            onVoltar: onVoltar,
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

class _RecursosAjudaConteudo extends StatelessWidget {
  final VoidCallback onVoltar;
  final ValueChanged<RecursoAjuda> onAbrirRecurso;

  const _RecursosAjudaConteudo({
    required this.onVoltar,
    required this.onAbrirRecurso,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Recursos do sistema',
            subtitulo: 'Veja o que o app oferece e como usar',
            mostrarVoltar: true,
            onVoltar: onVoltar,
            ajudaContextualTitulo: 'Recursos do sistema',
            ajudaContextualTexto: 'Consulte cada recurso e abra seu passo a passo.',
            ajudaContextualComoUsar: 'Toque em um cartão para ver as orientações detalhadas.',
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
                    onTap: () => onAbrirRecurso(recurso),
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

class _SecaoAjudaConteudo extends StatelessWidget {
  final CategoriaAjuda categoria;
  final VoidCallback onVoltar;

  const _SecaoAjudaConteudo({
    required this.categoria,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: categoria.titulo == 'Acesso e segurança' ? 'Primeiros passos' : categoria.titulo,
            subtitulo: 'Perguntas frequentes',
            mostrarVoltar: true,
            onVoltar: onVoltar,
            ajudaContextualTitulo: categoria.titulo,
            ajudaContextualTexto: categoria.descricao,
            ajudaContextualComoUsar: 'Abra uma pergunta para ver a orientação completa.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  categoria.descricao,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ...categoria.itens.map((item) => _FaqTile(item: item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemasAjudaConteudo extends StatelessWidget {
  final VoidCallback onVoltar;

  const _ProblemasAjudaConteudo({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Problemas comuns',
            subtitulo: 'Solução de problemas',
            mostrarVoltar: true,
            onVoltar: onVoltar,
            ajudaContextualTitulo: 'Problemas comuns',
            ajudaContextualTexto: 'Consulte orientações para dificuldades conhecidas no uso do aplicativo.',
            ajudaContextualComoUsar: 'Abra um item para ler a orientação correspondente.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'Encontre orientações para dificuldades conhecidas no uso do Gestor de Vendas.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ...problemasAjuda.map((item) => _FaqTile(item: item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackAjudaConteudo extends StatefulWidget {
  final VoidCallback onVoltar;

  const _FeedbackAjudaConteudo({required this.onVoltar});

  @override
  State<_FeedbackAjudaConteudo> createState() => _FeedbackAjudaConteudoState();
}

class _FeedbackAjudaConteudoState extends State<_FeedbackAjudaConteudo> {
  final _auth = AuthClient();
  final _assunto = TextEditingController();
  final _descricao = TextEditingController();
  String _tipo = 'sugestao';
  bool _enviando = false;

  @override
  void dispose() {
    _assunto.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final assunto = _assunto.text.trim();
    final descricao = _descricao.text.trim();
    if (descricao.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva a sugestão ou o problema com um pouco mais de detalhes.')),
      );
      return;
    }

    setState(() => _enviando = true);
    final erro = await _auth.enviarFeedback(
      tipo: _tipo,
      assunto: assunto,
      mensagem: descricao,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro)),
      );
      return;
    }
    _assunto.clear();
    _descricao.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensagem enviada com sucesso. Obrigado por contribuir.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Sugestões e falhas',
            subtitulo: 'Ajude a melhorar o sistema',
            mostrarVoltar: true,
            onVoltar: widget.onVoltar,
            ajudaContextualTitulo: 'Sugestões e falhas',
            ajudaContextualTexto: 'Use este espaço para enviar uma ideia de melhoria ou relatar um comportamento inesperado.',
            ajudaContextualComoUsar: 'Descreva o que aconteceu, em qual tela e o que você esperava que acontecesse.',
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
                    'Sua mensagem será guardada no sistema para análise. Não inclua CPF, nome, telefone, dados de clientes, senha, token, chave ou senha mestra.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de mensagem',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sugestao', child: Text('Sugestão de melhoria')),
                    DropdownMenuItem(value: 'falha', child: Text('Relato de falha')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _tipo = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _assunto,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Assunto (opcional)',
                    prefixIcon: Icon(Icons.short_text),
                    counterText: '',
                  ),
                  maxLength: 120,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descricao,
                  minLines: 6,
                  maxLines: 10,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descreva a sugestão ou a falha',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 78),
                      child: Icon(Icons.edit_note_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_enviando ? 'Enviando...' : 'Enviar mensagem'),
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
