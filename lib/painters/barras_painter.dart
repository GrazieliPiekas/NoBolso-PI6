import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../graphics/viewport.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import 'texto.dart';

class ItemBarra {
  final String rotulo;
  final double valor;
  final Color cor;
  const ItemBarra(this.rotulo, this.valor, this.cor);
}

/// Barras: "Quanto gastei em cada categoria?"
/// A largura útil é dividida em N faixas e cada barra ocupa 60% da sua faixa.
class BarrasPainter extends CustomPainter {
  final List<ItemBarra> itens;
  final double progresso;

  BarrasPainter(this.itens, {this.progresso = 1});

  @override
  void paint(Canvas canvas, Size size) {
    if (itens.isEmpty) return;
    final maximo = Viewport.maximoAgradavel(itens.map((e) => e.valor).reduce(math.max));

    // Decide se os rótulos cabem deitados; se não, gira e reserva mais base.
    final estiloRotulo = const TextStyle(color: Cores.textoSuave, fontSize: 11);
    final larguraFaixaEstimada = size.width * 0.84 / itens.length;
    final maiorRotulo = itens
        .map((e) => medirTexto(e.rotulo, estiloRotulo).width)
        .reduce(math.max);
    final girar = maiorRotulo > larguraFaixaEstimada - 4;

    // Rótulo girado 45°: ocupa ~0,71·largura na vertical e para a esquerda.
    const seno45 = 0.7071;
    final alturaRotulo = medirTexto('Ag', estiloRotulo).height;
    final baseNecessaria = girar
        ? (maiorRotulo + alturaRotulo) * seno45 + 10
        : alturaRotulo + 10;
    final primeiro = medirTexto(itens.first.rotulo, estiloRotulo).width;
    final esquerdaNecessaria = girar
        ? primeiro * seno45 - larguraFaixaEstimada / 2 + 4
        : 0.0;

    final vp = Viewport.comMargens(
      size,
      xMin: 0,
      xMax: itens.length.toDouble(),
      yMin: 0,
      yMax: maximo,
      esquerda: math.max(0.14, esquerdaNecessaria / size.width),
      direita: 0.02,
      topo: 0.08,
      base: math.min(0.5, baseNecessaria / size.height),
    );

    // Grade horizontal com 4 divisões e valores à esquerda.
    final grade = Paint()
      ..color = Cores.trilho
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final v = maximo * i / 4;
      final y = vp.yTela(v);
      canvas.drawLine(Offset(vp.area.left, y), Offset(vp.area.right, y), grade);
      desenharTexto(
        canvas,
        Formatadores.moedaCurta((v * 100).round()).replaceFirst(r'R$ ', ''),
        Offset(vp.area.left - 6, y),
        ancora: Ancora.direita,
        estilo: const TextStyle(color: Cores.textoSuave, fontSize: 10),
      );
    }

    final larguraFaixa = vp.escalaX; // 1 unidade do mundo = 1 faixa
    final larguraBarra = larguraFaixa * 0.6;
    for (var i = 0; i < itens.length; i++) {
      final item = itens[i];
      final centroX = vp.xTela(i + 0.5);
      final topo = vp.yTela(item.valor * progresso);
      final base = vp.yTela(0);
      final rect = Rect.fromLTRB(
        centroX - larguraBarra / 2,
        topo,
        centroX + larguraBarra / 2,
        base,
      );
      final raio = Radius.circular(math.min(6, larguraBarra / 3));
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: raio, topRight: raio),
        Paint()..color = item.cor,
      );

      if (girar) {
        desenharTexto(
          canvas,
          item.rotulo,
          Offset(centroX + 4, base + 8),
          estilo: estiloRotulo,
          anguloRad: -math.pi / 4,
        );
      } else {
        desenharTexto(
          canvas,
          item.rotulo,
          Offset(centroX, base + 6),
          estilo: estiloRotulo,
          ancora: Ancora.topoCentro,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BarrasPainter old) =>
      old.progresso != progresso || old.itens != itens;
}
