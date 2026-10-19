import 'package:flutter/foundation.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';

/// Lista de lançamentos do mês com filtros de tipo, categoria, "só fixos"
/// e busca por texto em tempo real.
class LancamentosViewModel extends ChangeNotifier {
  final _dao = LancamentoDao();

  DateTime mes = DateTime.now();
  Tipo? tipo;
  int? categoriaId;
  bool somenteFixos = false;
  String busca = '';
  List<Categoria> categorias = [];

  /// Lançamentos do mês vindos do banco (antes da busca e do "só fixos").
  List<Lancamento>? _doMes;

  /// Carrega as categorias (para o filtro) e os lançamentos do mês atual.
  LancamentosViewModel() {
    Eventos.dadosAlterados.addListener(carregar);
    CategoriaDao().listar().then((lista) {
      categorias = lista;
      notifyListeners();
    });
    carregar();
  }

  /// Categorias que fazem sentido para o tipo escolhido.
  List<Categoria> get categoriasDoTipo => categorias
      .where((categoria) => tipo == null || categoria.tipo == tipo)
      .toList();

  /// Resultado final mostrado na tela. A busca roda na memória a cada tecla,
  /// por isso o filtro é instantâneo.
  List<Lancamento>? get itens {
    final todos = _doMes;
    if (todos == null) return null;
    final termo = _normalizar(busca);
    return todos
        .where((lancamento) => !somenteFixos || lancamento.fixo)
        .where(
          (lancamento) =>
              termo.isEmpty ||
              _normalizar(lancamento.descricao).contains(termo) ||
              _normalizar(lancamento.categoriaNome ?? '').contains(termo),
        )
        .toList();
  }

  Totais? get totais {
    final lista = itens;
    if (lista == null) return null;
    var receitas = 0;
    var despesas = 0;
    for (final item in lista) {
      if (item.tipo == Tipo.receita) {
        receitas += item.valorCentavos;
      } else {
        despesas += item.valorCentavos;
      }
    }
    return Totais(receitas, despesas, lista.length);
  }

  /// Busca no banco os lançamentos do mês com os filtros de tipo e categoria.
  /// A busca por texto e o "só fixos" são aplicados depois, em [itens].
  Future<void> carregar() async {
    _doMes = await _dao.listar(
      periodo: Periodo.mes(mes),
      tipo: tipo,
      categoriaId: categoriaId,
    );
    notifyListeners();
  }

  /// delta = -1 vai pro mês anterior, +1 vai pro próximo.
  void mudarMes(int delta) {
    mes = DateTime(mes.year, mes.month + delta, 1);
    _doMes = null;
    notifyListeners();
    carregar();
  }

  void mudarTipo(Tipo? novoTipo) {
    tipo = novoTipo;
    categoriaId = null;
    notifyListeners();
    carregar();
  }

  void mudarCategoria(int? id) {
    categoriaId = id;
    notifyListeners();
    carregar();
  }

  /// Chamado a cada letra digitada. Só guarda o texto e redesenha:
  /// o filtro de verdade acontece no getter [itens].
  void buscar(String texto) {
    busca = texto;
    notifyListeners();
  }

  void alternarSomenteFixos(bool valor) {
    somenteFixos = valor;
    notifyListeners();
  }

  /// Tira da lista na hora (pro Dismissible não reclamar) e depois apaga do banco.
  Future<void> excluir(Lancamento lancamento) async {
    _doMes?.removeWhere((item) => item.id == lancamento.id);
    notifyListeners();
    await _dao.excluir(lancamento.id!);
    Eventos.notificarDados();
  }

  /// Ignora maiúsculas e acentos: "saude" encontra "Saúde".
  static String _normalizar(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const semAcento = 'aaaaaeeeeiiiiooooouuuuc';
    final resultado = StringBuffer();
    for (final letra in texto.toLowerCase().trim().split('')) {
      final posicao = comAcento.indexOf(letra);
      resultado.write(posicao >= 0 ? semAcento[posicao] : letra);
    }
    return resultado.toString();
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(carregar);
    super.dispose();
  }
}
