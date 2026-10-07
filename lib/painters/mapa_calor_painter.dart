import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/dados_graficos_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import 'texto.dart';

/// Mapa de calor: "Em quais dias meus gastos se concentram?"
/// Grade de 7 colunas (dias da semana) × N linhas. Célula = min(larg/7, alt/linhas).
/// Cor = Color.lerp(claro, verde escuro, valor / máximo).
class MapaCalorPainter extends CustomPainter {
  final MatrizCalor matriz;
  final double progresso;

  MapaCalorPainter(this.matriz, {this.progresso = 1});

  static const corMinima = Color(0xFFE4E2D6);
  static const corMaxima = Color(0xFF3E6A46);

  static Color corPara(double fracao) =>
      Color.lerp(corMinima, corMaxima, fracao.clamp(0.0, 1.0))!;

  @override
  void paint(Canvas canvas, Size size) {
    final linhas = matriz.valores.length;
    if (linhas == 0) return;

    const larguraRotulo = 40.0;
    const alturaCabecalho = 20.0;
    final larguraUtil = size.width - larguraRotulo;
    final alturaUtil = size.height - alturaCabecalho;
    final celula = math.min(larguraUtil / 7, alturaUtil / linhas);
    final espaco = celula * 0.12;
    // Centraliza a grade na largura disponível.
    final x0 = larguraRotulo + (larguraUtil - celula * 7) / 2;
    final y0 = alturaCabecalho;

    final estiloCab = const TextStyle(
      color: Cores.textoSuave,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    for (var c = 0; c < 7; c++) {
      desenharTexto(
        canvas,
        Formatadores.diasSemanaCurtos[c],
        Offset(x0 + celula * (c + 0.5), alturaCabecalho / 2),
        estilo: estiloCab,
      );
    }

    final maximo = matriz.maximo;
    for (var l = 0; l < linhas; l++) {
      final y = y0 + celula * l;
      desenharTexto(
        canvas,
        matriz.rotulosLinhas[l],
        Offset(x0 - 6, y + celula / 2),
        ancora: Ancora.direita,
        estilo: const TextStyle(color: Cores.textoSuave, fontSize: 10),
      );
      for (var c = 0; c < 7; c++) {
        final v = matriz.valores[l][c];
        if (v == null) continue;
        final fracao = maximo == 0 ? 0.0 : v / maximo;
        // Animação: as células "acendem" do claro até a cor final.
        final cor = corPara(fracao * progresso);
        final rect = Rect.fromLTWH(
          x0 + celula * c + espaco / 2,
          y + espaco / 2,
          celula - espaco,
          celula - espaco,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(celula * 0.18)),
          Paint()..color = cor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MapaCalorPainter old) =>
      old.progresso != progresso || old.matriz != matriz;

  /// Altura ideal para uma largura, mantendo as células quadradas.
  static double alturaPara(double largura, int linhas) {
    final celula = (largura - 40) / 7;
    return 20 + celula * linhas;
  }
}
