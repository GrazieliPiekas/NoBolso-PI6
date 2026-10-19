import 'package:flutter/material.dart';

import '../models/categoria.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../viewmodels/categoria_form_view_model.dart';

/// Criar / editar categoria. Devolve a categoria salva (com id) ou null.
class CategoriaFormDialog extends StatefulWidget {
  final Categoria? editar;

  /// Tipo travado (chip "+ Nova" do formulário de lançamento).
  final Tipo? tipoFixo;

  /// Tipo já marcado, mas que pode ser trocado (aba atual de Categorias).
  final Tipo? tipoInicial;

  const CategoriaFormDialog({
    super.key,
    this.editar,
    this.tipoFixo,
    this.tipoInicial,
  });

  static Future<Categoria?> abrir(
    BuildContext context, {
    Categoria? editar,
    Tipo? tipoFixo,
    Tipo? tipoInicial,
  }) => showDialog<Categoria>(
    context: context,
    builder: (_) => CategoriaFormDialog(
      editar: editar,
      tipoFixo: tipoFixo,
      tipoInicial: tipoInicial,
    ),
  );

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  late final _viewModel = CategoriaFormViewModel(
    editar: widget.editar,
    tipoInicial: widget.tipoFixo ?? widget.tipoInicial,
  );
  late final _nome = TextEditingController(text: widget.editar?.nome);

  @override
  void dispose() {
    _nome.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final salva = await _viewModel.salvar(_nome.text);
    if (salva != null && mounted) Navigator.pop(context, salva);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _dialogo(),
  );

  Widget _dialogo() => AlertDialog(
    title: Text(widget.editar == null ? 'Nova categoria' : 'Editar categoria'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nome,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nome',
              errorText: _viewModel.erro,
            ),
            onChanged: (_) => _viewModel.limparErro(),
          ),
          if (widget.tipoFixo == null) ...[
            const SizedBox(height: 4),
            SegmentedButton<Tipo>(
              segments: const [
                ButtonSegment(value: Tipo.despesa, label: Text('Despesa')),
                ButtonSegment(value: Tipo.receita, label: Text('Receita')),
              ],
              selected: {_viewModel.tipo},
              onSelectionChanged: (selecao) =>
                  _viewModel.definirTipo(selecao.first),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Cor', style: TextStyle(color: Cores.textoSuave)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final cor in Cores.paletaCategorias)
                Semantics(
                  selected: cor.toARGB32() == _viewModel.cor,
                  button: true,
                  child: GestureDetector(
                    onTap: () => _viewModel.definirCor(cor.toARGB32()),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cor.toARGB32() == _viewModel.cor
                              ? Cores.texto
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: cor.toARGB32() == _viewModel.cor
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(
        onPressed: _viewModel.salvando ? null : _salvar,
        child: const Text('Salvar'),
      ),
    ],
  );
}
