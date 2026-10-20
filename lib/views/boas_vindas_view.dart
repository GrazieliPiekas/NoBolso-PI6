import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../viewmodels/boas_vindas_view_model.dart';
import 'abertura_view.dart';

/// Primeira abertura: pergunta como chamar a pessoa (opcional). Sem cadastro nem login.
class BoasVindasView extends StatefulWidget {
  final VoidCallback onConcluir;
  const BoasVindasView({super.key, required this.onConcluir});

  @override
  State<BoasVindasView> createState() => _BoasVindasViewState();
}

class _BoasVindasViewState extends State<BoasVindasView> {
  final _nome = TextEditingController();
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = BoasVindasViewModel();

  @override
  void dispose() {
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _concluir({required bool comNome}) async {
    await _viewModel.concluir(comNome ? _nome.text : null);
    widget.onConcluir();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: degradeVerde),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: limites.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const MarcaNoBolso(tamanhoIcone: 110),
                  const SizedBox(height: 44),
                  const Text(
                    'Como podemos te chamar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Cores.creme,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                    onPressed: _viewModel.salvando
                        ? null
                        : () => _concluir(comNome: true),
                    child: const Text('Começar'),
                  ),
                  TextButton(
                    onPressed: _viewModel.salvando
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
