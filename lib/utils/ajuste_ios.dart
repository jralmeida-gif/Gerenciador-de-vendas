import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Correção de layout para o PWA instalado no iOS.
///
/// O Flutter Web dimensiona a interface pelo tamanho da janela e **não** lê as
/// safe areas do CSS (`env(safe-area-inset-*)`). Quando o app roda em modo
/// standalone (adicionado à tela de início), o iOS reporta uma altura
/// provisória durante o boot e o `MediaQuery.padding` pode chegar zerado,
/// fazendo o cabeçalho subir para trás do relógio/bateria e a barra inferior
/// ficar sob o indicador de gestos.
///
/// Este widget garante um padding mínimo coerente com o aparelho enquanto o
/// navegador não informa os valores reais — e passa a respeitar os valores
/// verdadeiros assim que eles chegam.
class AjusteIos extends StatelessWidget {
  final Widget child;
  const AjusteIos({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final mq = MediaQuery.of(context);
    final tamanho = mq.size;

    // Aparelhos com notch/Dynamic Island têm proporção alta (>= ~2:1).
    // Em telas curtas (iPhone SE, iPad) não há área insegura no topo.
    final proporcao = tamanho.height / (tamanho.width == 0 ? 1 : tamanho.width);
    final provavelNotch = proporcao >= 1.9 && tamanho.width < 500;

    final topoMinimo = provavelNotch ? 44.0 : 20.0;
    final baseMinima = provavelNotch ? 22.0 : 0.0;

    final padding = mq.padding.copyWith(
      top: mq.padding.top < topoMinimo ? topoMinimo : mq.padding.top,
      bottom: mq.padding.bottom < baseMinima ? baseMinima : mq.padding.bottom,
    );

    return MediaQuery(
      data: mq.copyWith(
        padding: padding,
        viewPadding: padding,
        // Evita que a fonte gigante do sistema quebre os cartões do painel.
        textScaler: mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        ),
      ),
      child: child,
    );
  }
}
