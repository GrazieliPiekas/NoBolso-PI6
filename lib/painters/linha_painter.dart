import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../graphics/curvas.dart';
import '../graphics/viewport.dart';
import '../services/dados_graficos_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import 'texto.dart';

/// Linha: "Como meu saldo evoluiu?"
/// Pontos no viewport → Catmull-Rom → Bézier cúbica (Path.cubicTo), área com degradê e marcadores.
class LinhaPainter extends CustomPainter {
  final SerieLinha serie;
  final double progresso;

  LinhaPainter(this.serie, {this.progresso = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final valores = serie.valores;
    if (valores.isEmpty) return;

    final (yMin, yMax, passo) = Viewport.eixoAgradavel(
      valores.reduce(math.min),
      valores.reduce(math.max),
    );

    final viewport = Viewport.comMargens(
      size,
      xMin: 0,
      xMax: math.max(1, valores.length - 1).toDouble(),
      yMin: yMin,
      yMax: yMax,
      esquerda: 0.15,
      direita: 0.05,
      topo: 0.08,
      base: 0.14,
    );

    // Grade nos múltiplos do passo.
    final grade = Paint()
      ..color = Cores.trilho
      ..strokeWidth = 1;
    for (var valor = yMin; valor <= yMax + passo / 2; valor += passo) {
      final y = viewport.yTela(valor);
      canvas.drawLine(
        Offset(viewport.area.left, y),
        Offset(viewport.area.right, y),
        grade,
      );
      desenharTexto(
        canvas,
        Formatadores.moedaCurta((valor * 100).round()).replaceFirst(r'R$ ', ''),
        Offset(viewport.area.left - 6, y),
        ancora: Ancora.direita,
        estilo: const TextStyle(color: Cores.textoSuave, fontSize: 10),
      );
    }
    if (viewport.yMin < 0) {
      canvas.drawLine(
        Offset(viewport.area.left, viewport.yTela(0)),
        Offset(viewport.area.right, viewport.yTela(0)),
        Paint()
          ..color = Cores.textoSuave.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    // Os pontos "crescem" a partir do zero durante a animação.
    final pontos = [
      for (var i = 0; i < valores.length; i++)
        viewport.paraTela(
          valores.length == 1 ? 0.5 : i.toDouble(),
          valores[i] * progresso,
        ),
    ];
    final curva = catmullRomParaBezier(pontos);

    // Área sob a curva com degradê vertical.
    final base = viewport.yTela(math.max(0, viewport.yMin));
    final area = Path.from(curva)
      ..lineTo(pontos.last.dx, base)
      ..lineTo(pontos.first.dx, base)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Cores.verde.withValues(alpha: 0.25),
            Cores.verde.withValues(alpha: 0.02),
          ],
        ).createShader(viewport.area),
    );

    canvas.drawPath(
      curva,
      Paint()
        ..color = Cores.verde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Marcadores (todos se forem poucos pontos; senão só o último).
    final mostrarTodos = pontos.length <= 14;
    for (var i = 0; i < pontos.length; i++) {
      final ultimo = i == pontos.length - 1;
      if (!mostrarTodos && !ultimo) continue;
      if (ultimo) {
        canvas.drawCircle(
          pontos[i],
          10,
          Paint()..color = Cores.verde.withValues(alpha: 0.18),
        );
      }
      canvas.drawCircle(pontos[i], 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        pontos[i],
        5,
        Paint()
          ..color = Cores.verde
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Rótulos do eixo X.
    for (var i = 0; i < serie.rotulos.length; i++) {
      if (serie.rotulos[i].isEmpty) continue;
      desenharTexto(
        canvas,
        serie.rotulos[i],
        Offset(pontos[i].dx, viewport.area.bottom + 8),
        ancora: Ancora.topoCentro,
      );
    }
  }

  @override
  bool shouldRepaint(LinhaPainter anterior) =>
      anterior.progresso != progresso || anterior.serie != serie;
}
