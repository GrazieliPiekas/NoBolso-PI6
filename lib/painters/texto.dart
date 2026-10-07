import 'package:flutter/painting.dart';

import '../theme/app_theme.dart';

enum Ancora { centro, esquerda, direita, topoCentro, baseCentro }

/// Desenha um texto com TextPainter, posicionado pela âncora escolhida.
/// Retorna o tamanho ocupado.
Size desenharTexto(
  Canvas canvas,
  String texto,
  Offset pos, {
  TextStyle estilo = const TextStyle(color: Cores.textoSuave, fontSize: 11),
  Ancora ancora = Ancora.centro,
  double anguloRad = 0,
}) {
  final tp = medirTexto(texto, estilo);
  final deslocamento = switch (ancora) {
    Ancora.centro => Offset(-tp.width / 2, -tp.height / 2),
    Ancora.esquerda => Offset(0, -tp.height / 2),
    Ancora.direita => Offset(-tp.width, -tp.height / 2),
    Ancora.topoCentro => Offset(-tp.width / 2, 0),
    Ancora.baseCentro => Offset(-tp.width / 2, -tp.height),
  };
  if (anguloRad == 0) {
    tp.paint(canvas, pos + deslocamento);
  } else {
    // Rótulo girado: save → translate → rotate → paint → restore.
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(anguloRad);
    tp.paint(canvas, Offset(-tp.width, -tp.height / 2));
    canvas.restore();
  }
  return Size(tp.width, tp.height);
}

TextPainter medirTexto(String texto, TextStyle estilo) => TextPainter(
  text: TextSpan(
    text: texto,
    style: estilo.copyWith(fontFamily: estilo.fontFamily ?? AppTheme.fonte),
  ),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();
