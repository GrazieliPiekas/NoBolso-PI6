import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fundo verde com degradê usado na abertura e nas boas-vindas.
const degradeVerde = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF3D6744), Color(0xFF28432F)],
);

/// Logo + nome, reaproveitado na abertura e nas boas-vindas.
class MarcaNoBolso extends StatelessWidget {
  final double tamanhoIcone;
  const MarcaNoBolso({super.key, this.tamanhoIcone = 140});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(tamanhoIcone * 0.22),
        child: Image.asset(
          'assets/images/icone_nobolso.png',
          width: tamanhoIcone,
          height: tamanhoIcone,
          semanticLabel: 'Logo do NoBolso',
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        '.nobolso',
        style: TextStyle(
          color: Cores.creme,
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'suas finanças, no seu bolso',
        style: TextStyle(color: Color(0xFFC9CDB8), fontSize: 16),
      ),
    ],
  );
}

class AberturaScreen extends StatelessWidget {
  const AberturaScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: degradeVerde),
      child: SafeArea(
        child: Column(
          children: [
            Spacer(),
            MarcaNoBolso(),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Text(
                '100% offline · seus dados ficam no aparelho',
                style: TextStyle(color: Color(0xFF9FAA94), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
