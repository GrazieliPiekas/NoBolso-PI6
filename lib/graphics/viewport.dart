import 'dart:math' as math;
import 'dart:ui';

/// Transformação mundo → tela (translação, escala e inversão do Y).
///
///   xTela = margemEsq + (x − xMin) · (larguraÚtil / (xMax − xMin))
///   yTela = margemTopo + alturaÚtil − (y − yMin) · (alturaÚtil / (yMax − yMin))
///
/// As margens são frações do `size`, então o gráfico se adapta a qualquer tela.
class Viewport {
  final Rect area;
  final double xMin, xMax, yMin, yMax;

  Viewport({
    required this.area,
    required this.xMin,
    required double xMax,
    required this.yMin,
    required double yMax,
  }) : xMax = xMax == xMin ? xMin + 1 : xMax,
       yMax = yMax == yMin ? yMin + 1 : yMax;

  /// Cria o viewport a partir do tamanho do canvas e de margens proporcionais.
  factory Viewport.comMargens(
    Size size, {
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    double esquerda = 0.04,
    double direita = 0.04,
    double topo = 0.06,
    double base = 0.14,
  }) {
    final area = Rect.fromLTRB(
      size.width * esquerda,
      size.height * topo,
      size.width * (1 - direita),
      size.height * (1 - base),
    );
    return Viewport(area: area, xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax);
  }

  double get escalaX => area.width / (xMax - xMin);
  double get escalaY => area.height / (yMax - yMin);

  /// Converte um x "do mundo" (índice, valor) para o pixel na tela.
  double xTela(double x) => area.left + (x - xMin) * escalaX;

  /// Mesma ideia do xTela, mas o Y é invertido: no Canvas o 0 fica em cima.
  double yTela(double y) => area.top + area.height - (y - yMin) * escalaY;

  Offset paraTela(double x, double y) => Offset(xTela(x), yTela(y));

  /// Arredonda o máximo de um eixo para um valor "redondo" (1, 2, 2,5, 5 × 10ⁿ),
  /// para as linhas de grade caírem em números legíveis.
  static double maximoAgradavel(double valor) {
    if (valor <= 0) return 1;
    final expoente = math.pow(10, (math.log(valor) / math.ln10).floor());
    final fracao = valor / expoente;
    final passo = fracao <= 1
        ? 1
        : fracao <= 2
        ? 2
        : fracao <= 2.5
        ? 2.5
        : fracao <= 5
        ? 5
        : 10;
    return passo * expoente.toDouble();
  }

  /// Eixo com [divisoes] intervalos de tamanho "redondo" que cobre [menor, maior].
  /// Retorna (mínimo, máximo, passo). Ex.: −200..4.900 → (−2.000, 6.000, 2.000).
  static (double, double, double) eixoAgradavel(
    double menor,
    double maior, {
    int divisoes = 4,
  }) {
    final minimo = math.min(0.0, menor);
    final maximo = math.max(0.0, maior);
    if (maximo == minimo) return (0, 1, 0.25);
    var passo = maximoAgradavel((maximo - minimo) / divisoes);
    // Garante que o arredondamento para múltiplos do passo não exceda as divisões.
    while (((maximo / passo).ceil() - (minimo / passo).floor()) > divisoes) {
      passo = maximoAgradavel(passo * 1.01);
    }
    return (
      (minimo / passo).floor() * passo,
      (maximo / passo).ceil() * passo,
      passo,
    );
  }
}
