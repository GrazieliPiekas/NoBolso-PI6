import 'package:flutter/material.dart';

import '../database/configuracao_dao.dart';
import '../theme/app_theme.dart';
import 'abertura_screen.dart';

/// Primeira abertura: pergunta como chamar a pessoa (opcional). Sem cadastro nem login.
class BoasVindasScreen extends StatefulWidget {
  final VoidCallback onConcluir;
  const BoasVindasScreen({super.key, required this.onConcluir});

  @override
  State<BoasVindasScreen> createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen> {
  final _nome = TextEditingController();
  final _dao = ConfiguracaoDao();
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _concluir({required bool comNome}) async {
    setState(() => _salvando = true);
    if (comNome && _nome.text.trim().isNotEmpty) {
      await _dao.salvarNome(_nome.text);
    }
    await _dao.marcarBoasVindasVista();
    widget.onConcluir();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: degradeVerde),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const MarcaNoBolso(tamanhoIcone: 110),
                  const SizedBox(height: 44),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Como podemos te chamar?',
                      style: TextStyle(
                        color: Cores.creme,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 30,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _concluir(comNome: true),
                    style: const TextStyle(color: Cores.texto, fontSize: 17),
                    decoration: const InputDecoration(
                      hintText: 'Seu nome ou apelido',
                      fillColor: Cores.creme,
                      counterStyle: TextStyle(color: Color(0xFF9FAA94)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Cores.creme,
                      foregroundColor: Cores.verdeEscuro,
                    ),
                    onPressed: _salvando
                        ? null
                        : () => _concluir(comNome: true),
                    child: const Text('Começar'),
                  ),
                  TextButton(
                    onPressed: _salvando
                        ? null
                        : () => _concluir(comNome: false),
                    child: const Text(
                      'Pular',
                      style: TextStyle(color: Color(0xFFC9CDB8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Color(0xFF9FAA94),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem conta, sem nuvem e sem login. Tudo o que você '
                          'registrar fica só neste aparelho e funciona sem internet.',
                          style: TextStyle(
                            color: Color(0xFF9FAA94),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
