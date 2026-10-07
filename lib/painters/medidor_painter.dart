import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Medidor: "Quanto do orçamento já usei?"
/// Arco de fundo de 180° + arco de valor com varredura π · min(%, 1).
/// A cor muda nas faixas de 50/80/100%. O ponteiro é desenhado com
/// save → translate → rotate → drawLine → restore.
class MedidorPainter extends CustomPainter {
  final double percentual;
  final double progresso;

  MedidorPainter(this.percentual, {this.progresso = 1});

  static Color corDaFaixa(double p) => p >= 1
      ? Cores.despesa
      : p >= 0.8
      ? Cores.alerta
      : p >= 0.5
      ? const Color(0xFF5E8A55)
      : Cores.verde;

  @override
  void paint(Canvas canvas, Size size) {
    final espessura = size.width * 0.075;
    final raio = math.min(size.width / 2, size.height) - espessura / 2 - 2;
    final centro = Offset(size.width / 2, size.height - 2);
    final rect = Rect.fromCircle(center: centro, radius: raio);

    final fundo = Paint()
      ..color = Cores.trilho
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, fundo);

    final p = percentual * progresso;
    final varredura = math.pi * math.min(p, 1.0);
    if (varredura > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        varredura,
        false,
        Paint()
          ..color = corDaFaixa(p)
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessura
          ..strokeCap = StrokeCap.round,
      );
    }

    // Marcas discretas dos níveis 50% e 80%.
    final marca = Paint()
      ..color = Cores.cartao
      ..strokeWidth = 2;
    for (final nivel in const [0.5, 0.8]) {
      final a = math.pi + math.pi * nivel;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        centro + dir * (raio - espessura / 2),
        centro + dir * (raio + espessura / 2),
        marca,
      );
    }

    // Ponteiro.
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(math.pi + varredura);
    canvas.drawLine(
      Offset.zero,
      Offset(raio * 0.62, 0),
      Paint()
        ..color = Cores.texto
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    canvas.drawCircle(centro, espessura * 0.35, Paint()..color = Cores.texto);
  }

  @override
  bool shouldRepaint(MedidorPainter old) =>
      old.percentual != percentual || old.progresso != progresso;
}
