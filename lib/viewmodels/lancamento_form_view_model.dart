import 'package:flutter/foundation.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../services/orcamento_service.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../utils/validadores.dart';

/// Novo / editar lançamento: tipo, categoria, data, "fixo", validação e gravação.
/// Os textos digitados (valor e descrição) ficam nos controllers da View e
/// chegam aqui só na hora de salvar.
class LancamentoFormViewModel extends ChangeNotifier {
  final Lancamento? editar;
  final _categoriasDao = CategoriaDao();
  final _dao = LancamentoDao();

  Tipo tipo;
  int? categoriaId;
  DateTime data;
  bool fixo;
  List<Categoria> categorias = [];
  bool carregando = true;
  bool salvando = false;
  String? erroValor;
  String? erroCategoria;

  LancamentoFormViewModel({this.editar})
    : tipo = editar?.tipo ?? Tipo.despesa,
      categoriaId = editar?.categoriaId,
      data = editar?.data ?? DateTime.now(),
      fixo = editar?.fixo ?? false {
    carregarCategorias();
  }

  bool get edicao => editar != null;

  /// Carrega só as categorias do tipo escolhido (despesa ou receita).
  /// Se a categoria marcada não for desse tipo, desmarca.
  Future<void> carregarCategorias() async {
    final lista = await _categoriasDao.listar(tipo: tipo);
    categorias = lista;
    carregando = false;
    if (!lista.any((opcao) => opcao.id == categoriaId)) categoriaId = null;
    notifyListeners();
  }

  /// Trocar entre Despesa e Receita limpa a categoria, porque as listas são diferentes.
  void trocarTipo(Tipo novoTipo) {
    if (novoTipo == tipo) return;
    tipo = novoTipo;
    categoriaId = null;
    erroCategoria = null;
    notifyListeners();
    carregarCategorias();
  }

  void escolherCategoria(int? id) {
    categoriaId = id;
    erroCategoria = null;
    notifyListeners();
  }

  /// Depois de criar uma categoria pelo chip "+ Nova".
  Future<void> categoriaCriada(Categoria nova) async {
    await carregarCategorias();
    escolherCategoria(nova.id);
  }

  void definirData(DateTime novaData) {
    data = novaData;
    notifyListeners();
  }

  void definirFixo(bool marcado) {
    fixo = marcado;
    notifyListeners();
  }

  void limparErroValor() {
    if (erroValor == null) return;
    erroValor = null;
    notifyListeners();
  }

  /// RF11: valida valor e categoria antes de salvar. Devolve null se a validação
  /// falhar; senão, os avisos de orçamento para mostrar junto da confirmação.
  /// Erros do banco são relançados para a View exibir.
  Future<List<String>?> salvar({
    required String valorTexto,
    required String descricaoTexto,
  }) async {
    erroValor = Validadores.valor(valorTexto);
    erroCategoria = Validadores.categoria(categoriaId);
    notifyListeners();
    if (erroValor != null || erroCategoria != null) return null;

    final categoria = categorias.firstWhere((opcao) => opcao.id == categoriaId);
    final descricao = descricaoTexto.trim().isEmpty
        ? categoria.nome
        : descricaoTexto.trim();
    final lancamento = Lancamento(
      id: editar?.id,
      descricao: descricao,
      valorCentavos: Formatadores.centavosDeTexto(valorTexto)!,
      tipo: tipo,
      categoriaId: categoriaId!,
      data: data,
      fixo: fixo,
    );

    salvando = true;
    notifyListeners();
    try {
      if (edicao) {
        await _dao.atualizar(lancamento);
      } else {
        await _dao.inserir(lancamento);
      }
      final alertas = await OrcamentoService().verificarAlertas();
      Eventos.notificarDados();
      return alertas;
    } catch (_) {
      salvando = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Exclui o lançamento que está sendo editado.
  Future<void> excluir() async {
    await _dao.excluir(editar!.id!);
    Eventos.notificarDados();
  }
}
