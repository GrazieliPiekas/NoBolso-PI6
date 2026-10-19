import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'texto.dart';

/// Uma fatia da rosca: valor (define o tamanho do arco) e cor.
class FatiaRosca {
  final double valor;
  final Color cor;
  const FatiaRosca(this.valor, this.cor);
}

/// Rosca: "Qual a proporção entre receitas e despesas?"
/// Ângulo de cada fatia = 2π · valor / total, começando em −π/2 (topo).
/// Cada fatia é um Path: arco externo + arco interno no sentido contrário.
class RoscaPainter extends CustomPainter {
  final List<FatiaRosca> fatias;
  final String textoCentro;
  final String subtextoCentro;
  final double progresso;

  RoscaPainter(
    this.fatias, {
    required this.textoCentro,
    required this.subtextoCentro,
    this.progresso = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raioExterno = math.min(size.width, size.height) / 2 - 2;
    final raioInterno = raioExterno * 0.62;
    final externo = Rect.fromCircle(center: centro, radius: raioExterno);
    final interno = Rect.fromCircle(center: centro, radius: raioInterno);

    final total = fatias.fold<double>(0, (soma, fatia) => soma + fatia.valor);
    if (total <= 0) {
      // Sem dados: anel vazio.
      canvas.drawPath(
        _fatia(externo, interno, -math.pi / 2, 2 * math.pi - 0.0001),
        Paint()..color = Cores.trilho,
      );
    } else {
      var inicio = -math.pi / 2;
      // Com uma fatia só (100%), o separador apareceria como um corte no topo.
      final variasFatias = fatias.where((fatia) => fatia.valor > 0).length > 1;
      final separador = Paint()
        ..color = Cores.cartao
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      for (final fatia in fatias) {
        if (fatia.valor <= 0) continue;
        final varredura = 2 * math.pi * (fatia.valor / total) * progresso;
        if (varredura <= 0) continue;
        final path = _fatia(
          externo,
          interno,
          inicio,
          math.min(varredura, 2 * math.pi - 0.0001),
        );
        canvas.drawPath(path, Paint()..color = fatia.cor);
        if (variasFatias) canvas.drawPath(path, separador);
        inicio += varredura;
      }
    }

    desenharTexto(
      canvas,
      textoCentro,
      centro.translate(0, -8),
      estilo: TextStyle(
        color: Cores.texto,
        fontWeight: FontWeight.w800,
        fontSize: raioInterno * 0.30,
      ),
    );
    desenharTexto(
      canvas,
      subtextoCentro,
      centro.translate(0, raioInterno * 0.28),
      estilo: TextStyle(color: Cores.textoSuave, fontSize: raioInterno * 0.2),
    );
  }

  Path _fatia(Rect externo, Rect interno, double inicio, double varredura) =>
      Path()
        ..arcTo(externo, inicio, varredura, true)
        ..arcTo(interno, inicio + varredura, -varredura, false)
        ..close();

  @override
  bool shouldRepaint(RoscaPainter anterior) =>
      anterior.progresso != progresso ||
      anterior.fatias != fatias ||
      anterior.textoCentro != textoCentro;
}
