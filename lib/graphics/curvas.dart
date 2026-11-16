import 'dart:ui';

import 'package:flutter/animation.dart';

/// Pontos de controle da curva entre cada par de pontos vizinhos.
///
/// Para ir do ponto Pi até o Pi+1 usamos uma curva de Bézier cúbica.
/// Os dois pontos de controle saem da fórmula de Catmull-Rom:
///   C1 = Pi   + (Pi+1 − Pi−1) / 6
///   C2 = Pi+1 − (Pi+2 − Pi)   / 6
/// No primeiro e no último trecho falta um vizinho, então repetimos a ponta.
List<(Offset, Offset)> controlesCatmullRom(List<Offset> pts) {
  final controles = <(Offset, Offset)>[];
  for (var i = 0; i < pts.length - 1; i++) {
    final anterior = pts[i == 0 ? 0 : i - 1];
    final atual = pts[i];
    final proximo = pts[i + 1];
    final depois = pts[i + 2 < pts.length ? i + 2 : pts.length - 1];
    final c1 = atual + (proximo - anterior) / 6;
    final c2 = proximo - (depois - atual) / 6;
    controles.add((c1, c2));
  }
  return controles;
}

/// Monta uma linha suave que passa por todos os pontos (gráfico de linha).
Path catmullRomParaBezier(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  final controles = controlesCatmullRom(pts);
  for (var i = 0; i < controles.length; i++) {
    final (c1, c2) = controles[i];
    final destino = pts[i + 1];
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, destino.dx, destino.dy);
  }
  return path;
}

/// Curva de velocidade das animações dos gráficos (começa rápido e freia no fim).
///
/// É uma Bézier cúbica que vai de (0,0) até (1,1), igual ao `cubic-bezier` do CSS:
///   B(t) = 3(1−t)²t·P1 + 3(1−t)t²·P2 + t³
/// O Flutter manda o tempo da animação (x) e quer de volta o quanto ela andou (y).
/// Para isso achamos o t que dá esse x e calculamos o y nesse mesmo t.
class EasingBezier extends Curve {
  final double x1, y1, x2, y2;

  const EasingBezier(this.x1, this.y1, this.x2, this.y2);

  /// Curva usada nos gráficos do app.
  static const suave = EasingBezier(0.22, 1.0, 0.36, 1.0);

  /// Valor da Bézier no ponto t (serve tanto para o x quanto para o y).
  static double _bezier(double t, double p1, double p2) {
    final u = 1 - t;
    return 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t;
  }

  /// Acha o t em que a curva chega no x pedido, dividindo o intervalo
  /// ao meio várias vezes (busca binária). 30 vezes já dá bastante precisão.
  double _acharT(double x) {
    var baixo = 0.0;
    var alto = 1.0;
    var t = x;
    for (var i = 0; i < 30; i++) {
      t = (baixo + alto) / 2;
      if (_bezier(t, x1, x2) < x) {
        baixo = t;
      } else {
        alto = t;
      }
    }
    return t;
  }

  @override
  double transformInternal(double t) => _bezier(_acharT(t), y1, y2);
}
