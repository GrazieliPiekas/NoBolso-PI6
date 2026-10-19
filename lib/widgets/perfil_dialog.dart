import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../viewmodels/perfil_view_model.dart';

/// Perfil local: só o nome, guardado no SQLite. Em modo debug mostra o gerador
/// de lançamentos fictícios para testes de desempenho e com participantes.
class PerfilDialog extends StatefulWidget {
  const PerfilDialog({super.key});

  static Future<void> abrir(BuildContext context) =>
      showDialog(context: context, builder: (_) => const PerfilDialog());

  @override
  State<PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<PerfilDialog> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = PerfilViewModel();
  final _nome = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.nomeAtual().then((nomeSalvo) => _nome.text = nomeSalvo ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await _viewModel.salvarNome(_nome.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _dialogo(),
  );

  Widget _dialogo() => AlertDialog(
    title: const Text('Seu perfil'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nome,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Como podemos te chamar?',
            ),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: Cores.verde),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Não existe conta nem login. Seus dados ficam só neste '
                  'aparelho e nada é enviado para a internet.',
                  style: TextStyle(color: Cores.textoSuave, fontSize: 13),
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const Divider(height: 32),
            const Text(
              'Ferramentas de teste (só em debug)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final quantidade in const [100, 1000, 10000])
                  OutlinedButton(
                    onPressed: _viewModel.ocupado
                        ? null
                        : () => _viewModel.gerar(quantidade),
                    child: Text('+$quantidade'),
                  ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Cores.despesa,
                  ),
                  onPressed: _viewModel.ocupado ? null : _viewModel.apagarTudo,
                  child: const Text('Apagar lançamentos'),
                ),
              ],
            ),
            if (_viewModel.ocupado) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(color: Cores.verde),
            ],
            if (_viewModel.status != null) ...[
              const SizedBox(height: 8),
              Text(_viewModel.status!, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(onPressed: _salvar, child: const Text('Salvar')),
    ],
  );
}
