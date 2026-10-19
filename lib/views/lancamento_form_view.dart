import 'package:flutter/material.dart';

import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../utils/moeda_input_formatter.dart';
import '../viewmodels/lancamento_form_view_model.dart';
import '../widgets/componentes.dart';
import 'categoria_form_dialog.dart';

/// Novo / editar lançamento. Fluxo curto (RF12): tipo → valor → categoria → salvar;
/// data já vem como hoje e a descrição é sugerida pela categoria se ficar vazia.
class LancamentoFormView extends StatefulWidget {
  final Lancamento? editar;
  const LancamentoFormView({super.key, this.editar});

  static Future<void> abrir(BuildContext context, {Lancamento? editar}) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => LancamentoFormView(editar: editar),
        ),
      );

  @override
  State<LancamentoFormView> createState() => _LancamentoFormViewState();
}

class _LancamentoFormViewState extends State<LancamentoFormView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  late final _viewModel = LancamentoFormViewModel(editar: widget.editar);
  final _valor = TextEditingController();
  final _descricao = TextEditingController();

  @override
  void initState() {
    super.initState();
    final lancamentoEditado = widget.editar;
    if (lancamentoEditado != null) {
      _valor.text = MoedaInputFormatter.formatar(
        lancamentoEditado.valorCentavos,
      );
      _descricao.text = lancamentoEditado.descricao;
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _novaCategoria() async {
    final nova = await CategoriaFormDialog.abrir(
      context,
      tipoFixo: _viewModel.tipo,
    );
    if (nova != null) await _viewModel.categoriaCriada(nova);
  }

  Future<void> _escolherData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _viewModel.data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dataEscolhida != null) _viewModel.definirData(dataEscolhida);
  }

  Future<void> _salvar() async {
    final List<String>? alertas;
    try {
      alertas = await _viewModel.salvar(
        valorTexto: _valor.text,
        descricaoTexto: _descricao.text,
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
      return;
    }
    if (alertas == null || !mounted) return;
    // RF10: confirmação visível.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          [
            _viewModel.edicao ? 'Lançamento atualizado' : 'Lançamento salvo',
            ...alertas,
          ].join('\n'),
        ),
        duration: Duration(seconds: alertas.isEmpty ? 2 : 5),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            style: TextButton.styleFrom(foregroundColor: Cores.despesa),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await _viewModel.excluir();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lançamento excluído')));
    Navigator.pop(context);
  }

  // A tela também escuta o campo de valor: a linha abaixo dele muda de cor ao digitar.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_viewModel, _valor]),
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() {
    final corTipo = _viewModel.tipo == Tipo.despesa
        ? Cores.despesa
        : Cores.verde;
    return Scaffold(
      backgroundColor: Cores.cabecalho,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _viewModel.edicao ? 'Editar lançamento' : 'Novo lançamento',
        ),
        actions: [
          if (_viewModel.edicao)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _viewModel.salvando ? null : _excluir,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _SeletorTipo(
                    tipo: _viewModel.tipo,
                    aoTrocar: _viewModel.trocarTipo,
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Valor',
                      style: TextStyle(color: Cores.textoSuave, fontSize: 15),
                    ),
                  ),
                  // "R$" colado ao número e o conjunto centralizado.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        r'R$ ',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Cores.texto,
                        ),
                      ),
                      Flexible(
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _valor,
                            autofocus: !_viewModel.edicao,
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoedaInputFormatter()],
                            onChanged: (_) => _viewModel.limparErroValor(),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Cores.texto,
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              isDense: true,
                              hintText: '0,00',
                              hintStyle: TextStyle(color: Cores.textoSuave),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    color: _viewModel.erroValor != null
                        ? Cores.despesa
                        : _valor.text.isEmpty
                        ? Cores.trilho
                        : corTipo.withValues(alpha: 0.5),
                  ),
                  if (_viewModel.erroValor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _viewModel.erroValor!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Cores.despesa,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  const Text(
                    'Categoria',
                    style: TextStyle(
                      color: Cores.textoSuave,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_viewModel.carregando)
                    const LinearProgressIndicator(color: Cores.verde)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final categoria in _viewModel.categorias)
                          _ChipCategoria(
                            rotulo: categoria.nome,
                            cor: categoria.color,
                            selecionado: categoria.id == _viewModel.categoriaId,
                            onTap: () =>
                                _viewModel.escolherCategoria(categoria.id),
                          ),
                        _ChipCategoria(
                          rotulo: '+ Nova',
                          cor: Cores.textoSuave,
                          selecionado: false,
                          onTap: _novaCategoria,
                        ),
                      ],
                    ),
                  if (_viewModel.erroCategoria != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _viewModel.erroCategoria!,
                        style: const TextStyle(
                          color: Cores.despesa,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  _CampoToque(
                    rotulo: 'Data',
                    valor: Formatadores.dataLonga(_viewModel.data),
                    onTap: _escolherData,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricao,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Ex.: Supermercado São José',
                      contentPadding: EdgeInsets.fromLTRB(20, 18, 20, 18),
                    ),
                  ),
                  // Opcional e desmarcado por padrão: não alonga o fluxo (RF12).
                  CheckboxListTile(
                    value: _viewModel.fixo,
                    onChanged: (marcado) =>
                        _viewModel.definirFixo(marcado ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: corTipo,
                    title: Text(
                      _viewModel.tipo == Tipo.despesa
                          ? 'Despesa fixa'
                          : 'Receita fixa',
                    ),
                    subtitle: const Text(
                      'Se repete todo mês (aluguel, salário...)',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
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
                    : Text(
                        _viewModel.edicao
                            ? 'Salvar alterações'
                            : 'Salvar lançamento',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeletorTipo extends StatelessWidget {
  final Tipo tipo;
  final ValueChanged<Tipo> aoTrocar;
  const _SeletorTipo({required this.tipo, required this.aoTrocar});

  @override
  Widget build(BuildContext context) {
    Widget opcao(Tipo tipoDaOpcao, Color cor) {
      final ativo = tipoDaOpcao == tipo;
      return Expanded(
        child: Semantics(
          selected: ativo,
          button: true,
          child: GestureDetector(
            onTap: () => aoTrocar(tipoDaOpcao),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ativo ? cor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                tipoDaOpcao.rotulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w400,
                  color: ativo ? Colors.white : Cores.textoSuave,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          opcao(Tipo.despesa, Cores.despesa),
          opcao(Tipo.receita, Cores.verde),
        ],
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String rotulo;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  const _ChipCategoria({
    required this.rotulo,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selecionado,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? cor : Cores.cartao,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selecionado ? cor : Cores.trilho,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Bolinha(selecionado ? Colors.white : cor),
            const SizedBox(width: 8),
            Text(
              rotulo,
              style: TextStyle(
                color: selecionado ? Colors.white : Cores.texto,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Campo que abre um seletor ao tocar (Data), no estilo do protótipo.
class _CampoToque extends StatelessWidget {
  final String rotulo;
  final String valor;
  final VoidCallback onTap;

  const _CampoToque({
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Cores.campo,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: const TextStyle(
                      color: Cores.textoSuave,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(valor, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Cores.textoSuave),
          ],
        ),
      ),
    ),
  );
}
