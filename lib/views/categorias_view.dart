import 'package:flutter/material.dart';

import '../database/categoria_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../viewmodels/categorias_view_model.dart';
import '../widgets/componentes.dart';
import 'categoria_form_dialog.dart';

/// CRUD de categorias (RF02): abas Despesas / Receitas, grade de cartões e busca
/// em tempo real. Excluir categoria em uso é bloqueado (decisão 6).
class CategoriasView extends StatefulWidget {
  const CategoriasView({super.key});
  @override
  State<CategoriasView> createState() => _CategoriasViewState();
}

class _CategoriasViewState extends State<CategoriasView>
    with SingleTickerProviderStateMixin {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = CategoriasViewModel();
  final _busca = TextEditingController();
  late final _abas = TabController(length: 2, vsync: this);

  static const _tipos = [Tipo.despesa, Tipo.receita];

  @override
  void dispose() {
    _abas.dispose();
    _busca.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _editar([Categoria? categoria]) async {
    final categoriaSalva = await CategoriaFormDialog.abrir(
      context,
      editar: categoria,
      tipoInicial: _tipos[_abas.index],
    );
    if (categoriaSalva != null) _viewModel.carregar();
  }

  Future<void> _excluir(Categoria categoria) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: Text('Excluir "${categoria.nome}"?'),
        content: const Text('A categoria será removida da lista.'),
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
    try {
      await _viewModel.excluir(categoria);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${categoria.nome}" excluída')));
      }
    } on CategoriaEmUsoException catch (erro) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Categoria em uso'),
          content: Text(erro.mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Categorias'),
      bottom: TabBar(
        controller: _abas,
        labelColor: Cores.verde,
        indicatorColor: Cores.verde,
        unselectedLabelColor: Cores.textoSuave,
        tabs: [for (final tipo in _tipos) Tab(text: tipo.rotuloPlural)],
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: Cores.verde,
      foregroundColor: Colors.white,
      onPressed: () => _editar(),
      icon: const Icon(Icons.add),
      label: const Text('Nova categoria'),
    ),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busca,
              onChanged: _viewModel.buscar,
              decoration: InputDecoration(
                hintText: 'Buscar categoria',
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
          Expanded(
            child: _viewModel.categorias == null
                ? const Carregando()
                : TabBarView(
                    controller: _abas,
                    children: [for (final tipo in _tipos) _grade(tipo)],
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _grade(Tipo tipo) {
    final categoriasDoTipo = _viewModel.doTipo(tipo);
    if (categoriasDoTipo.isEmpty) {
      return EstadoVazio(
        icone: Icons.sell_outlined,
        titulo: 'Nenhuma categoria',
        mensagem: _viewModel.busca.isEmpty
            ? 'Toque em "Nova categoria" para criar uma.'
            : 'Nada encontrado para "${_viewModel.busca}".',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: categoriasDoTipo.length,
      itemBuilder: (context, i) => _CartaoCategoria(
        categoriasDoTipo[i],
        onTap: () => _editar(categoriasDoTipo[i]),
        onExcluir: () => _excluir(categoriasDoTipo[i]),
      ),
    );
  }
}

class _CartaoCategoria extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const _CartaoCategoria(
    this.categoria, {
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Cores.cartao,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: categoria.color.withValues(alpha: 0.18),
                  child: Bolinha(categoria.color, tamanho: 16),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Cores.textoSuave,
                  ),
                  onPressed: onExcluir,
                ),
              ],
            ),
            const Spacer(),
            Text(
              categoria.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}
