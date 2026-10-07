import 'package:flutter/material.dart';

import '../database/categoria_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../widgets/componentes.dart';
import 'categoria_form_dialog.dart';

/// CRUD de categorias (RF02). Excluir categoria em uso é bloqueado (decisão 6).
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});
  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _dao = CategoriaDao();
  List<Categoria>? _categorias;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final l = await _dao.listar();
    if (mounted) setState(() => _categorias = l);
  }

  Future<void> _editar([Categoria? c]) async {
    final r = await CategoriaFormDialog.abrir(context, editar: c);
    if (r != null) _carregar();
  }

  Future<void> _excluir(Categoria c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir "${c.nome}"?'),
        content: const Text('A categoria será removida da lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Cores.despesa),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _dao.excluir(c.id!);
      Eventos.notificarDados();
      _carregar();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${c.nome}" excluída')));
      }
    } on CategoriaEmUsoException catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Categoria em uso'),
          content: Text(e.mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categorias;
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Cores.verde,
        foregroundColor: Colors.white,
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: cats == null
          ? const Carregando()
          : ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              children: [
                for (final tipo in const [Tipo.despesa, Tipo.receita])
                  CartaoSecao(
                    titulo: tipo.rotuloPlural,
                    padding: const EdgeInsets.fromLTRB(12, 16, 4, 8),
                    child: Column(
                      children: [
                        for (final c in cats.where((c) => c.tipo == tipo))
                          ListTile(
                            contentPadding: const EdgeInsets.only(left: 8),
                            leading: Bolinha(c.color, tamanho: 18),
                            title: Text(c.nome),
                            onTap: () => _editar(c),
                            trailing: IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Cores.textoSuave,
                              ),
                              onPressed: () => _excluir(c),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
