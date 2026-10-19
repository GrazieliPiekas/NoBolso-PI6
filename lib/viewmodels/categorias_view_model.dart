import 'package:flutter/foundation.dart';

import '../database/categoria_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../utils/eventos.dart';

/// CRUD de categorias (RF02) com busca por nome em tempo real.
class CategoriasViewModel extends ChangeNotifier {
  final _dao = CategoriaDao();

  List<Categoria>? categorias;
  String busca = '';

  CategoriasViewModel() {
    carregar();
  }

  /// Categorias de um tipo que combinam com a busca.
  List<Categoria> doTipo(Tipo tipo) {
    final termo = busca.trim().toLowerCase();
    return (categorias ?? [])
        .where((categoria) => categoria.tipo == tipo)
        .where(
          (categoria) =>
              termo.isEmpty || categoria.nome.toLowerCase().contains(termo),
        )
        .toList();
  }

  /// Lê todas as categorias do banco e avisa a View.
  Future<void> carregar() async {
    categorias = await _dao.listar();
    notifyListeners();
  }

  /// Chamado a cada letra digitada na busca. Não vai no banco, só filtra a lista.
  void buscar(String texto) {
    busca = texto;
    notifyListeners();
  }

  /// Lança [CategoriaEmUsoException] se a categoria tiver lançamentos ou orçamento.
  Future<void> excluir(Categoria categoria) async {
    await _dao.excluir(categoria.id!);
    Eventos.notificarDados();
    await carregar();
  }
}
