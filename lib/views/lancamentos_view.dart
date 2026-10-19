import 'package:flutter/material.dart';

import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../viewmodels/lancamentos_view_model.dart';
import '../widgets/componentes.dart';
import '../widgets/item_lancamento.dart';
import 'lancamento_form_view.dart';

/// Lista completa com busca em tempo real e filtros de período (mês), tipo,
/// categoria e "só fixos". Toque para editar, arraste para a esquerda para excluir.
class LancamentosView extends StatefulWidget {
  const LancamentosView({super.key});
  @override
  State<LancamentosView> createState() => _LancamentosViewState();
}

class _LancamentosViewState extends State<LancamentosView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = LancamentosViewModel();
  final _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<bool> _confirmarExclusao(Lancamento lancamento) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text(
          '"${lancamento.descricao}" de ${Formatadores.moeda(lancamento.valorCentavos)}',
        ),
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
    return confirmou == true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lançamentos')),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Column(
        children: [
          _filtros(),
          _resumo(),
          Expanded(child: _lista()),
        ],
      ),
    ),
  );

  // Material (e não Container colorido) para o CheckboxListTile mostrar o toque.
  Widget _filtros() => Material(
    color: Cores.cabecalho,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                onPressed: () => _viewModel.mudarMes(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  Formatadores.mesAno(_viewModel.mes),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                onPressed: () => _viewModel.mudarMes(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          // Busca em tempo real: filtra a cada letra digitada.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: TextField(
              controller: _busca,
              onChanged: _viewModel.buscar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por descrição ou categoria',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _viewModel.busca.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busca.clear();
                          _viewModel.buscar('');
                        },
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final opcao in [null, Tipo.receita, Tipo.despesa])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opcao?.rotuloPlural ?? 'Todos'),
                      selected: _viewModel.tipo == opcao,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontFamily: AppTheme.fonte,
                        color: _viewModel.tipo == opcao
                            ? Colors.white
                            : Cores.texto,
                      ),
                      onSelected: (_) => _viewModel.mudarTipo(opcao),
                    ),
                  ),
                DropdownButton<int?>(
                  value: _viewModel.categoriaId,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  hint: const Text('Categoria'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas as categorias'),
                    ),
                    for (final categoria in _viewModel.categoriasDoTipo)
                      DropdownMenuItem(
                        value: categoria.id,
                        child: Row(
                          children: [
                            Bolinha(categoria.color),
                            const SizedBox(width: 8),
                            Text(
                              _viewModel.tipo == null
                                  ? '${categoria.nome} (${categoria.tipo.rotulo.toLowerCase()})'
                                  : categoria.nome,
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _viewModel.mudarCategoria,
                ),
              ],
            ),
          ),
          CheckboxListTile(
            value: _viewModel.somenteFixos,
            onChanged: (marcado) =>
                _viewModel.alternarSomenteFixos(marcado ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            activeColor: Cores.verde,
            title: const Text('Mostrar só os fixos'),
          ),
        ],
      ),
    ),
  );

  Widget _resumo() {
    final totais = _viewModel.totais;
    if (totais == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            '${totais.quantidade} lançamento${totais.quantidade == 1 ? '' : 's'}',
            style: const TextStyle(color: Cores.textoSuave),
          ),
          const Spacer(),
          Text(
            'Saldo: ${Formatadores.moeda(totais.saldo)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _lista() {
    final itens = _viewModel.itens;
    if (itens == null) return const Carregando();
    if (itens.isEmpty) {
      return EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Nenhum lançamento',
        mensagem: _viewModel.busca.isNotEmpty
            ? 'Nada encontrado para "${_viewModel.busca}" neste mês.'
            : 'Não há lançamentos com esses filtros neste mês.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: itens.length,
      itemBuilder: (context, i) {
        final lancamento = itens[i];
        return Dismissible(
          key: ValueKey(lancamento.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmarExclusao(lancamento),
          onDismissed: (_) async {
            await _viewModel.excluir(lancamento);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lançamento excluído')),
              );
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Cores.despesa,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Cores.cartao,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ItemLancamento(
              lancamento,
              mostrarData: true,
              onTap: () =>
                  LancamentoFormView.abrir(context, editar: lancamento),
            ),
          ),
        );
      },
    );
  }
}
