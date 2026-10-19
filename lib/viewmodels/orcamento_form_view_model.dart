import 'package:flutter/foundation.dart';

import '../database/categoria_dao.dart';
import '../database/orcamento_dao.dart';
import '../models/categoria.dart';
import '../models/orcamento.dart';
import '../models/tipo.dart';
import '../services/notificacao_service.dart';
import '../services/orcamento_service.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../utils/validadores.dart';

/// A que o orçamento se aplica (escolha exclusiva, feita com RadioButtons).
enum EscopoOrcamento { geral, categoria }

/// Formulário de orçamento mensal recorrente: geral ou de uma categoria de despesa.
class OrcamentoFormViewModel extends ChangeNotifier {
  final Orcamento? editar;
  final _dao = OrcamentoDao();

  EscopoOrcamento? escopo;
  int? categoriaId;
  List<Categoria> opcoes = [];
  bool geralDisponivel = true;
  String? erro;
  bool salvando = false;

  /// Se for edição, já marca o radio certo (geral ou categoria).
  OrcamentoFormViewModel({this.editar, bool geral = false}) {
    final orcamentoEditado = editar;
    if (orcamentoEditado != null) {
      escopo = orcamentoEditado.geral
          ? EscopoOrcamento.geral
          : EscopoOrcamento.categoria;
      categoriaId = orcamentoEditado.categoriaId;
    } else if (geral) {
      escopo = EscopoOrcamento.geral;
    }
    _carregar();
  }

  bool get edicao => editar != null;

  /// Só oferece categorias de despesa que ainda não têm orçamento.
  Future<void> _carregar() async {
    final existentes = await _dao.listar();
    final usadas = existentes
        .where((orcamento) => orcamento.id != editar?.id)
        .map((orcamento) => orcamento.categoriaId)
        .toSet();
    final categoriasDespesa = await CategoriaDao().listar(tipo: Tipo.despesa);
    geralDisponivel = !usadas.contains(null);
    opcoes = categoriasDespesa
        .where((categoria) => !usadas.contains(categoria.id))
        .toList();
    escopo ??= geralDisponivel
        ? EscopoOrcamento.geral
        : EscopoOrcamento.categoria;
    if (escopo == EscopoOrcamento.categoria && categoriaId == null) {
      categoriaId = opcoes.isEmpty ? null : opcoes.first.id;
    }
    notifyListeners();
  }

  /// Chamado pelo RadioGroup. Na edição não deixa trocar.
  void definirEscopo(EscopoOrcamento? novoEscopo) {
    if (novoEscopo == null || edicao) return;
    escopo = novoEscopo;
    if (novoEscopo == EscopoOrcamento.categoria && categoriaId == null) {
      categoriaId = opcoes.isEmpty ? null : opcoes.first.id;
    }
    erro = null;
    notifyListeners();
  }

  void definirCategoria(int? id) {
    categoriaId = id;
    notifyListeners();
  }

  void limparErro() {
    if (erro == null) return;
    erro = null;
    notifyListeners();
  }

  /// Devolve null se não salvou (erro em [erro]); senão, os avisos de orçamento.
  Future<List<String>?> salvar(String limiteTexto) async {
    final erroValor = Validadores.valor(limiteTexto);
    final semAlvo =
        escopo == null ||
        (escopo == EscopoOrcamento.categoria && categoriaId == null);
    if (semAlvo || erroValor != null) {
      erro = erroValor ?? 'Escolha a que o orçamento se aplica';
      notifyListeners();
      return null;
    }
    salvando = true;
    notifyListeners();
    final orcamento = Orcamento(
      id: editar?.id,
      categoriaId: escopo == EscopoOrcamento.geral ? null : categoriaId,
      limiteCentavos: Formatadores.centavosDeTexto(limiteTexto)!,
    );
    try {
      if (edicao) {
        await _dao.atualizar(orcamento);
      } else {
        await _dao.inserir(orcamento);
      }
      await NotificacaoService.instance.pedirPermissao();
      final alertas = await OrcamentoService().verificarAlertas();
      Eventos.notificarDados();
      return alertas;
    } catch (excecao) {
      salvando = false;
      erro = excecao.toString();
      notifyListeners();
      return null;
    }
  }

  /// Remove o orçamento que está sendo editado.
  Future<void> excluir() async {
    await _dao.excluir(editar!.id!);
    Eventos.notificarDados();
  }
}
