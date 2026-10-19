import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/componentes.dart';

/// Sobre o app: logo, proposta e equipe.
class SobreView extends StatelessWidget {
  const SobreView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sobre o NoBolso')),
    body: ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        CartaoSecao(
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo_nobolso_escuro.png',
                height: 120,
                semanticLabel: 'Logo do NoBolso',
              ),
              const SizedBox(height: 12),
              const Text(
                'Finanças pessoais 100% offline. Sem conta bancária, sem nuvem, '
                'sem login e sem assinatura: tudo fica só neste aparelho.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.textoSuave),
              ),
            ],
          ),
        ),
        const CartaoSecao(
          titulo: 'Equipe',
          child: Text('Erick, Grazieli e Gustavo'),
        ),
        const CartaoSecao(
          titulo: 'Versão',
          child: Text('1.1.0 · Flutter + Dart + SQLite'),
        ),
      ],
    ),
  );
}
