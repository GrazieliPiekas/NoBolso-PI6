import 'package:flutter/material.dart';

import '../models/orcamento.dart';
import '../theme/app_theme.dart';
import '../utils/moeda_input_formatter.dart';
import '../viewmodels/orcamento_form_view_model.dart';
import '../widgets/componentes.dart';

/// Formulário de orçamento mensal recorrente: geral ou de uma categoria de despesa.
class OrcamentoFormSheet extends StatefulWidget {
  final Orcamento? editar;
  final bool geral;
  const OrcamentoFormSheet({super.key, this.editar, this.geral = false});

  static Future<void> abrir(
    BuildContext context, {
    Orcamento? editar,
    bool geral = false,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => OrcamentoFormSheet(editar: editar, geral: geral),
  );

  @override
  State<OrcamentoFormSheet> createState() => _OrcamentoFormSheetState();
}

class _OrcamentoFormSheetState extends State<OrcamentoFormSheet> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  late final _viewModel = OrcamentoFormViewModel(
    editar: widget.editar,
    geral: widget.geral,
  );
  final _limite = TextEditingController();

  @override
  void initState() {
    super.initState();
    final orcamentoEditado = widget.editar;
    if (orcamentoEditado != null) {
      _limite.text = MoedaInputFormatter.formatar(
        orcamentoEditado.limiteCentavos,
      );
    }
  }

  @override
  void dispose() {
    _limite.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final alertas = await _viewModel.salvar(_limite.text);
    if (alertas == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(['Orçamento salvo', ...alertas].join('\n'))),
    );
    Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Remover orçamento?'),
        content: Text('"${widget.editar!.nome}" deixará de ser acompanhado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            style: TextButton.styleFrom(foregroundColor: Cores.despesa),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await _viewModel.excluir();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Orçamento removido')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _viewModel.edicao ? 'Editar orçamento' : 'Novo orçamento mensal',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vale para todos os meses; você pode mudar quando quiser.',
              style: TextStyle(color: Cores.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplicar a',
              style: TextStyle(
                color: Cores.textoSuave,
                fontWeight: FontWeight.w700,
              ),
            ),
            _escolhaEscopo(),
            if (_viewModel.escopo == EscopoOrcamento.categoria) ...[
              const SizedBox(height: 4),
              _escolhaCategoria(),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _limite,
              autofocus: !_viewModel.edicao,
              keyboardType: TextInputType.number,
              inputFormatters: [MoedaInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Limite por mês',
                prefixText: r'R$ ',
                errorText: _viewModel.erro,
              ),
              onChanged: (_) => _viewModel.limparErro(),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _viewModel.salvando ? null : _salvar,
              child: _viewModel.salvando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar orçamento'),
            ),
            if (_viewModel.edicao)
              TextButton(
                onPressed: _viewModel.salvando ? null : _excluir,
                style: TextButton.styleFrom(foregroundColor: Cores.despesa),
                child: const Text('Remover orçamento'),
              ),
          ],
        ),
      ),
    ),
  );

  /// RadioGroup: escolha exclusiva entre orçamento geral e de uma categoria.
  /// Na edição o alvo não muda (trocar seria outro orçamento).
  Widget _escolhaEscopo() => RadioGroup<EscopoOrcamento>(
    groupValue: _viewModel.escopo,
    onChanged: _viewModel.definirEscopo,
    child: Column(
      children: [
        RadioListTile<EscopoOrcamento>(
          value: EscopoOrcamento.geral,
          enabled:
              !_viewModel.edicao && _viewModel.geralDisponivel ||
              _viewModel.escopo == EscopoOrcamento.geral,
          contentPadding: EdgeInsets.zero,
          activeColor: Cores.verde,
          title: const Text('Orçamento geral do mês'),
          subtitle: !_viewModel.geralDisponivel && !_viewModel.edicao
              ? const Text('Você já tem um orçamento geral')
              : null,
        ),
        RadioListTile<EscopoOrcamento>(
          value: EscopoOrcamento.categoria,
          enabled:
              !_viewModel.edicao && _viewModel.opcoes.isNotEmpty ||
              _viewModel.escopo == EscopoOrcamento.categoria,
          contentPadding: EdgeInsets.zero,
          activeColor: Cores.verde,
          title: const Text('Uma categoria de despesa'),
        ),
      ],
    ),
  );

  Widget _escolhaCategoria() => DropdownButtonFormField<int>(
    // A key recria o campo quando a lista chega do banco.
    key: ValueKey(_viewModel.opcoes.length),
    initialValue:
        _viewModel.opcoes.any(
          (categoria) => categoria.id == _viewModel.categoriaId,
        )
        ? _viewModel.categoriaId
        : null,
    decoration: const InputDecoration(labelText: 'Categoria'),
    items: [
      for (final categoria in _viewModel.opcoes)
        DropdownMenuItem(
          value: categoria.id,
          child: Row(
            children: [
              Bolinha(categoria.color),
              const SizedBox(width: 8),
              Text(categoria.nome),
            ],
          ),
        ),
    ],
    onChanged: _viewModel.edicao ? null : _viewModel.definirCategoria,
  );
}
