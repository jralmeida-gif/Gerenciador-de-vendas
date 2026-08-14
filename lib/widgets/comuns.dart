import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cabeçalho azul curvo usado no topo das telas de formulário.
class HeaderCurvo extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> acoes;
  final bool mostrarVoltar;
  final Widget? rodape;

  const HeaderCurvo({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acoes = const [],
    this.mostrarVoltar = true,
    this.rodape,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mostrarVoltar)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  else
                    const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitulo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitulo!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...acoes,
                ],
              ),
              if (rodape != null) ...[const SizedBox(height: 14), rodape!],
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
