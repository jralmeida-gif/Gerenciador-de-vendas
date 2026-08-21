import 'dart:math' as math;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/agenda.dart';
import '../screens/configuracoes.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Cabeçalho azul curvo usado no topo das telas de formulário.
class HeaderCurvo extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> acoes;
  final bool mostrarAcoesGlobais;
  final bool voltarGlobal;
  final Widget? rodape;
  final bool mostrarVoltar;
  final String? ajudaContextualTitulo;
  final String? ajudaContextualTexto;
  final String? ajudaContextualComoUsar;
  final String? ajudaContextualAtencao;

  const HeaderCurvo({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acoes = const [],
    this.mostrarAcoesGlobais = true,
    this.voltarGlobal = false,
    this.rodape,
    this.mostrarVoltar = false,
    this.ajudaContextualTitulo,
    this.ajudaContextualTexto,
    this.ajudaContextualComoUsar,
    this.ajudaContextualAtencao,
  });

  Widget _avatar(AppState estado) {
    if (estado.avatarData.isEmpty) return const Icon(Icons.person, color: Colors.white, size: 28);
    try {
      final encoded = estado.avatarData.contains(',') ? estado.avatarData.split(',').last : estado.avatarData;
      return ClipOval(
        child: Transform.translate(
          offset: Offset(estado.avatarOffsetX * 28, estado.avatarOffsetY * 28),
          child: Transform.scale(
            scale: estado.avatarScale,
            child: Image.memory(base64Decode(encoded), width: 48, height: 48, fit: BoxFit.cover),
          ),
        ),
      );
    } catch (_) {
      return const Icon(Icons.person, color: Colors.white, size: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final usuario = estado.authUser;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mostrarVoltar)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          final voltar = voltarGlobal ? estado.onVoltarGlobal : null;
                          if (voltar != null) {
                            voltar();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                  if (mostrarAcoesGlobais && usuario != null) ...[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: _avatar(estado),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gestor de Vendas', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                        if (usuario != null)
                          Text('${Fmt.data(DateTime.now())} · ${estado.nomeUsuario}', style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 11.5)),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ),
                        if (subtitulo != null)
                          Text(subtitulo!, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
              if (acoes.isNotEmpty || ajudaContextualTitulo != null || (mostrarAcoesGlobais && usuario != null)) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...acoes,
                      if (mostrarAcoesGlobais && usuario != null && titulo != 'Agenda')
                        _AtalhoCabecalho(
                          rotulo: 'Agenda',
                          icone: Icons.event_note_outlined,
                          onTap: () {
                            final abrir = estado.onAbrirAgenda;
                            if (abrir != null) {
                              abrir();
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaAgenda()));
                            }
                          },
                        ),
                      if (mostrarAcoesGlobais && usuario != null && estado.onAbrirClientes != null)
                        _AtalhoCabecalho(
                          rotulo: 'Clientes',
                          icone: Icons.people_outline,
                          onTap: estado.onAbrirClientes!,
                        ),
                      if (ajudaContextualTitulo != null)
                        _AtalhoCabecalho(
                          rotulo: 'Ajuda',
                          icone: Icons.help_outline,
                          onTap: () => _mostrarAjudaContextual(context),
                        ),
                      if (mostrarAcoesGlobais && usuario != null && titulo != 'Configurações')
                        _AtalhoCabecalho(
                          rotulo: 'Configurações',
                          icone: Icons.settings_outlined,
                          onTap: () {
                            final abrir = estado.onAbrirConfiguracoes;
                            if (abrir != null) {
                              abrir();
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TelaConfiguracoes(user: usuario)));
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
              if (rodape != null) ...[const SizedBox(height: 14), rodape!],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAjudaContextual(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.help_outline, color: AppColors.primary), const SizedBox(width: 9), Expanded(child: Text(ajudaContextualTitulo ?? 'Ajuda', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)))]),
            const SizedBox(height: 14),
            const Text('O que esta tela faz', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(ajudaContextualTexto ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            const Text('Como usar', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(ajudaContextualComoUsar ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
            if (ajudaContextualAtencao != null) ...[
              const SizedBox(height: 12),
              Container(width: double.infinity, padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)), child: Text('Atenção: $ajudaContextualAtencao', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
            ],
          ]),
        ),
      ),
    );
  }
}

class _AtalhoCabecalho extends StatelessWidget {
  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;
  const _AtalhoCabecalho({required this.rotulo, required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: rotulo == 'Configurações' ? 78 : 62,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: Colors.white, size: 22),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(rotulo, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card branco padrão com título opcional.
class CartaoSecao extends StatelessWidget {
  final String? titulo;
  final Widget child;
  final EdgeInsets padding;
  final Widget? acao;

  const CartaoSecao({
    super.key,
    this.titulo,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (titulo != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (acao != null) acao!,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Anel de progresso com percentual no centro.
class AnelProgresso extends StatelessWidget {
  final double valor; // 0..1+
  final double tamanho;
  final Color? cor;
  final String? legenda;

  const AnelProgresso({
    super.key,
    required this.valor,
    this.tamanho = 130,
    this.cor,
    this.legenda,
  });

  @override
  Widget build(BuildContext context) {
    final c = cor ?? AppColors.semaforo(valor);
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(
        painter: _AnelPainter(valor.clamp(0, 1).toDouble(), c),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(valor * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: tamanho * 0.24,
                  fontWeight: FontWeight.w800,
                  color: c,
                  height: 1,
                ),
              ),
              if (legenda != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    legenda!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  final double valor;
  final Color cor;
  _AnelPainter(this.valor, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = (size.width - stroke) / 2;

    final fundo = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centro, raio, fundo);

    final frente = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      -math.pi / 2,
      2 * math.pi * valor,
      false,
      frente,
    );
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) =>
      old.valor != valor || old.cor != cor;
}

/// Barra de progresso fina com semáforo.
class BarraProgresso extends StatelessWidget {
  final double valor;
  final double altura;
  const BarraProgresso({super.key, required this.valor, this.altura = 7});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: LinearProgressIndicator(
        value: valor.clamp(0, 1).toDouble(),
        minHeight: altura,
        backgroundColor: const Color(0xFFE8EDF3),
        valueColor: AlwaysStoppedAnimation(AppColors.semaforo(valor)),
      ),
    );
  }
}

/// Pequeno cartão de indicador (KPI).
class CartaoKpi extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final Color? cor;
  final VoidCallback? onTap;

  const CartaoKpi({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.cor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = cor ?? AppColors.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 18, color: c),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rotulo,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de status colorida.
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  final IconData? icone;
  const Etiqueta({
    super.key,
    required this.texto,
    required this.cor,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: cor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vazio amigável.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 40, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 6),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 18), acao!],
          ],
        ),
      ),
    );
  }
}

/// Campo de formulário padronizado com rótulo acima.
class CampoTexto extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final String? dica;
  final TextInputType? teclado;
  final List<dynamic>? formatadores;
  final String? Function(String?)? validador;
  final int maxLinhas;
  final Widget? prefixo;
  final Widget? sufixo;
  final bool habilitado;
  final FocusNode? focus;
  final TextCapitalization capitalizacao;
  final void Function(String)? onChanged;

  const CampoTexto({
    super.key,
    required this.rotulo,
    required this.controller,
    this.dica,
    this.teclado,
    this.formatadores,
    this.validador,
    this.maxLinhas = 1,
    this.prefixo,
    this.sufixo,
    this.habilitado = true,
    this.focus,
    this.capitalizacao = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            rotulo,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focus,
          keyboardType: teclado,
          enabled: habilitado,
          maxLines: maxLinhas,
          textCapitalization: capitalizacao,
          onChanged: onChanged,
          inputFormatters: formatadores?.cast(),
          validator: validador,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: dica,
            prefixIcon: prefixo,
            suffixIcon: sufixo,
          ),
        ),
      ],
    );
  }
}

/// Rótulo de botão que nunca quebra em duas linhas.
///
/// Em telas estreitas (ou com fonte do sistema aumentada) textos como
/// "CANCELAR" não cabiam na largura do botão e o Flutter quebrava a palavra.
/// Aqui o texto é forçado a uma única linha e reduzido proporcionalmente
/// apenas se realmente faltar espaço.
class RotuloBotao extends StatelessWidget {
  final String texto;
  const RotuloBotao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        texto,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

/// Campo de data opcional com digitação em dd/MM/aaaa e calendário auxiliar.
class CampoDataOpcional extends StatefulWidget {
  final String rotulo;
  final DateTime? valor;
  final ValueChanged<DateTime?> onChanged;

  const CampoDataOpcional({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  State<CampoDataOpcional> createState() => _CampoDataOpcionalState();
}

class _CampoDataOpcionalState extends State<CampoDataOpcional> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editando = false;

  String _texto(DateTime? data) => data == null ? '' : Fmt.data(data);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _texto(widget.valor));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant CampoDataOpcional oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valor != widget.valor && _controller.text != _texto(widget.valor)) {
      _controller.value = TextEditingValue(
        text: _texto(widget.valor),
        selection: TextSelection.collapsed(offset: _texto(widget.valor).length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _ativarEdicao() {
    setState(() => _editando = true);
    Future<void>.delayed(Duration.zero, () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _textoAlterado(String texto) {
    final digitos = Fmt.somenteDigitos(texto);
    if (digitos.isEmpty) {
      widget.onChanged(null);
    } else if (digitos.length == 8) {
      final data = Fmt.parseData(texto);
      if (data != null) widget.onChanged(data);
    }
  }

  Future<void> _escolher(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: widget.valor ?? DateTime(1980, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data de nascimento',
    );
    if (data == null) return;
    _controller.text = Fmt.data(data);
    widget.onChanged(data);
  }

  String? _validar(String? texto) {
    final value = texto?.trim() ?? '';
    if (value.isEmpty) return null;
    if (Fmt.somenteDigitos(value).length != 8 || Fmt.parseData(value) == null) {
      return 'Informe uma data válida no formato dd/mm/aaaa';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !_editando,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: [DataInputFormatter()],
      onChanged: _textoAlterado,
      validator: _validar,
      decoration: InputDecoration(
        labelText: widget.rotulo,
        hintText: 'dd/mm/aaaa',
        prefixIcon: const Icon(Icons.cake_outlined, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _editando ? 'Concluir edição' : 'Digitar data',
              onPressed: () {
                if (_editando) {
                  _focusNode.unfocus();
                  setState(() => _editando = false);
                } else {
                  _ativarEdicao();
                }
              },
              icon: Icon(_editando ? Icons.check_rounded : Icons.edit_outlined, size: 19),
            ),
            IconButton(
              tooltip: 'Escolher no calendário',
              onPressed: () => _escolher(context),
              icon: const Icon(Icons.calendar_month_outlined, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de seção usado na ficha consolidada para separar prospecções sem venda.
class TituloSecaoLista extends StatelessWidget {
  final String texto;
  const TituloSecaoLista(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.25))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              texto.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.25))),
        ],
      ),
    );
  }
}


/// Menu inferior usado em formulários abertos acima do shell principal.
/// Ao selecionar uma aba, o shell fecha a rota de formulário e muda de seção.
class MenuRodapeApp extends StatelessWidget {
  final int abaSelecionada;
  final ValueChanged<int> onSelecionar;

  const MenuRodapeApp({
    super.key,
    required this.abaSelecionada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _MenuRodapeItem(
                label: 'Início',
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                selected: abaSelecionada == 0,
                onTap: () => onSelecionar(0),
              ),
              _MenuRodapeItem(
                label: 'Vendas',
                icon: Icons.point_of_sale_outlined,
                selectedIcon: Icons.point_of_sale,
                selected: abaSelecionada == 1,
                onTap: () => onSelecionar(1),
              ),
              _MenuRodapeItem(
                label: 'Portab.',
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz,
                selected: abaSelecionada == 2,
                onTap: () => onSelecionar(2),
              ),
              _MenuRodapeItem(
                label: 'Prospec.',
                icon: Icons.phone_in_talk_outlined,
                selectedIcon: Icons.phone_in_talk,
                selected: abaSelecionada == 3,
                onTap: () => onSelecionar(3),
              ),
              _MenuRodapeItem(
                label: 'Relatórios',
                icon: Icons.insert_chart_outlined,
                selectedIcon: Icons.insert_chart,
                selected: abaSelecionada == 4,
                onTap: () => onSelecionar(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRodapeItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _MenuRodapeItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(selected ? selectedIcon : icon, size: 23, color: color),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de senha com controle explícito para mostrar ou ocultar o conteúdo.
class CampoSenha extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final bool enabled;

  const CampoSenha({
    super.key,
    required this.controller,
    required this.labelText,
    this.helperText,
    this.enabled = true,
  });

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _visivel = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: !_visivel,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _visivel ? 'Ocultar senha' : 'Mostrar senha',
          icon: Icon(_visivel ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _visivel = !_visivel),
        ),
      ),
    );
  }
}
