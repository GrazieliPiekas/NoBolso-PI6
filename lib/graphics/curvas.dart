import 'dart:ui';

import 'package:flutter/animation.dart';

/// Converte uma sequência de pontos numa curva suave que passa por todos eles.
///
/// Cada trecho Pi → Pi+1 da spline Catmull-Rom vira uma Bézier cúbica com controles:
///   C1 = Pi   + (Pi+1 − Pi−1) / 6
///   C2 = Pi+1 − (Pi+2 − Pi)   / 6
/// Nas pontas, o ponto inexistente é repetido (P−1 = P0, Pn+1 = Pn).
Path catmullRomParaBezier(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  if (pts.length == 1) return path;
  for (var i = 0; i < pts.length - 1; i++) {
    final p0 = pts[i == 0 ? 0 : i - 1];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = pts[i + 2 < pts.length ? i + 2 : pts.length - 1];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

/// Pontos de controle de cada trecho (útil para testes e para depuração).
List<(Offset, Offset)> controlesCatmullRom(List<Offset> pts) => [
  for (var i = 0; i < pts.length - 1; i++)
    (
      pts[i] + (pts[i + 1] - pts[i == 0 ? 0 : i - 1]) / 6,
      pts[i + 1] - (pts[i + 2 < pts.length ? i + 2 : pts.length - 1] - pts[i]) / 6,
    ),
];

/// Easing por Bézier cúbica com P0 = (0,0) e P3 = (1,1), como o `cubic-bezier` do CSS.
///
/// B(t) = 3(1−t)²t·P1 + 3(1−t)t²·P2 + t³
/// Para um progresso x, encontra t com Bx(t) = x (Newton-Raphson, com bisseção
/// como reserva) e devolve By(t).
class EasingBezier extends Curve {
  final double x1, y1, x2, y2;

  const EasingBezier(this.x1, this.y1, this.x2, this.y2);

  /// Saída suave, usada nas transições dos gráficos.
  static const suave = EasingBezier(0.22, 1.0, 0.36, 1.0);

  static double _bezier(double t, double a, double b) {
    final u = 1 - t;
    return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t;
  }

  static double _derivada(double t, double a, double b) {
    final u = 1 - t;
    return 3 * u * u * a + 6 * u * t * (b - a) + 3 * t * t * (1 - b);
  }

  double _resolverT(double x) {
    var t = x;
    for (var i = 0; i < 8; i++) {
      final erro = _bezier(t, x1, x2) - x;
      if (erro.abs() < 1e-6) return t;
      final d = _derivada(t, x1, x2);
      if (d.abs() < 1e-6) break;
      t -= erro / d;
    }
    var baixo = 0.0, alto = 1.0;
    t = x;
    for (var i = 0; i < 30; i++) {
      final v = _bezier(t, x1, x2);
      if ((v - x).abs() < 1e-6) break;
      if (v < x) {
        baixo = t;
      } else {
        alto = t;
      }
      t = (baixo + alto) / 2;
    }
    return t;
  }

  @override
  double transformInternal(double t) => _bezier(_resolverT(t), y1, y2);
}
