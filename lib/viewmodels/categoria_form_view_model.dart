import 'package:flutter/foundation.dart';

import '../database/categoria_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/validadores.dart';

/// Criar / editar categoria: nome, tipo e cor.
class CategoriaFormViewModel extends ChangeNotifier {
  final Categoria? editar;
  final _dao = CategoriaDao();

  Tipo tipo;
  int cor;
  String? erro;
  bool salvando = false;

  CategoriaFormViewModel({this.editar, Tipo? tipoInicial})
    : tipo = editar?.tipo ?? tipoInicial ?? Tipo.despesa,
      cor = editar?.cor ?? Cores.paletaCategorias[2].toARGB32();

  void definirTipo(Tipo novoTipo) {
    tipo = novoTipo;
    notifyListeners();
  }

  void definirCor(int novaCor) {
    cor = novaCor;
    notifyListeners();
  }

  void limparErro() {
    if (erro == null) return;
    erro = null;
    notifyListeners();
  }

  /// Devolve a categoria salva (com id) ou null se houve erro (mostrado em [erro]).
  Future<Categoria?> salvar(String nome) async {
    erro = Validadores.nomeCategoria(nome);
    if (erro != null) {
      notifyListeners();
      return null;
    }
    salvando = true;
    notifyListeners();
    final categoria = Categoria(
      id: editar?.id,
      nome: nome.trim(),
      tipo: tipo,
      cor: cor,
    );
    try {
      Categoria salva;
      if (categoria.id == null) {
        salva = categoria.copyWith(id: await _dao.inserir(categoria));
      } else {
        await _dao.atualizar(categoria);
        salva = categoria;
      }
      Eventos.notificarDados();
      return salva;
    } catch (excecao) {
      salvando = false;
      erro = excecao.toString();
      notifyListeners();
      return null;
    }
  }
}
