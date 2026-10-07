import 'package:flutter/material.dart';

import '../graphics/curvas.dart';

/// Envolve um CustomPainter e anima o `progresso` de 0 a 1 sempre que [chave]
/// muda (novos dados). A curva de tempo é a Bézier cúbica de curvas.dart.
class GraficoAnimado extends StatefulWidget {
  final Object? chave;
  final CustomPainter Function(double progresso) painter;
  final double altura;
  final String descricaoAcessivel;

  const GraficoAnimado({
    super.key,
    required this.chave,
    required this.painter,
    required this.altura,
    required this.descricaoAcessivel,
  });

  @override
  State<GraficoAnimado> createState() => _GraficoAnimadoState();
}

class _GraficoAnimadoState extends State<GraficoAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _controle,
    curve: EasingBezier.suave,
  );

  @override
  void initState() {
    super.initState();
    _controle.forward();
  }

  @override
  void didUpdateWidget(GraficoAnimado old) {
    super.didUpdateWidget(old);
    if (old.chave != widget.chave) _controle.forward(from: 0);
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.descricaoAcessivel,
    child: SizedBox(
      height: widget.altura,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => CustomPaint(painter: widget.painter(_anim.value)),
      ),
    ),
  );
}
