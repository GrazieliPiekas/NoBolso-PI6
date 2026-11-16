import 'package:flutter/foundation.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../services/lancamentos_fixos_service.dart';
import '../services/orcamento_service.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import 'carregamento_seguro.dart';

/// Lista de lançamentos do mês com filtros de tipo, categoria, "só fixos"
/// e busca por texto em tempo real.
class LancamentosViewModel extends ChangeNotifier with CarregamentoSeguro {
  final LancamentoDao _dao;
  final CategoriaDao _categoriasDao;

  DateTime mes = DateTime.now();
  Tipo? tipo;
  int? categoriaId;
  bool somenteFixos = false;
  String busca = '';
  List<Categoria> categorias = [];

  /// Lançamentos do mês vindos do banco (antes da busca e do "só fixos").
  List<Lancamento>? _doMes;

  /// Carrega as categorias (para o filtro) e os lançamentos do mês atual.
  /// Os DAOs podem ser trocados nos testes; no app usam o banco padrão.
  LancamentosViewModel({LancamentoDao? dao, CategoriaDao? categoriasDao})
    : _dao = dao ?? LancamentoDao(),
      _categoriasDao = categoriasDao ?? CategoriaDao() {
    Eventos.dadosAlterados.addListener(carregar);
    carregar();
  }

  /// Mês anterior ao que está na tela (de onde os fixos são copiados).
  DateTime get mesAnterior => DateTime(mes.year, mes.month - 1, 1);

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
  /// As categorias (do filtro) vêm junto, para ficarem em dia se forem editadas.
  Future<void> carregar() => carregarComSeguranca(() async {
    categorias = await _categoriasDao.listar();
    _doMes = await _dao.listar(
      periodo: Periodo.mes(mes),
      tipo: tipo,
      categoriaId: categoriaId,
    );
  });

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
  /// o filtro de verdade acontece em [itens].
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

  /// Botão "Desfazer" do aviso de exclusão: devolve o lançamento ao banco
  /// com o mesmo id, e todas as telas recarregam.
  Future<void> desfazerExclusao(Lancamento lancamento) async {
    await _dao.restaurar(lancamento);
    Eventos.notificarDados();
  }

  /// Copia os lançamentos fixos do mês anterior para o mês da tela.
  /// Devolve quantos foram criados (0 se não havia nada novo para copiar).
  Future<int> copiarFixosDoMesAnterior() async {
    final copiados = await LancamentosFixosService(_dao)
        .copiarDoMesAnterior(mes);
    if (copiados > 0) {
      await OrcamentoService(lancamentos: _dao).verificarAlertas();
      Eventos.notificarDados();
    }
    return copiados;
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
