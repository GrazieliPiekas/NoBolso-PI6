import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../services/filtro_relatorio.dart';
import '../services/recomendacao_service.dart';
import '../services/relatorio_pdf_service.dart';
import '../services/relatorio_planilha_service.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';

/// Relatórios: filtros De/Até, categoria e tipo; resumo; exportação; recomendações.
class RelatoriosViewModel extends ChangeNotifier {
  final _dao = LancamentoDao();

  Periodo periodo = Periodo.mes(DateTime.now());
  Tipo? tipo;
  Categoria? categoria;
  List<Categoria> categorias = [];
  Totais? totais;
  List<Recomendacao>? recomendacoes;
  bool exportando = false;

  /// Começa com o mês atual e escuta os eventos para manter o resumo em dia.
  RelatoriosViewModel() {
    Eventos.dadosAlterados.addListener(carregar);
    carregar();
  }

  FiltroRelatorio get filtro => FiltroRelatorio(
    periodo: periodo,
    tipo: tipo,
    categoriaId: categoria?.id,
    categoriaNome: categoria?.nome,
  );

  bool get semDados => (totais?.quantidade ?? 0) == 0;

  List<Categoria> get categoriasDoTipo =>
      categorias.where((opcao) => tipo == null || opcao.tipo == tipo).toList();

  /// Busca categorias, totais e recomendações do período escolhido.
  Future<void> carregar() async {
    final todasCategorias = await CategoriaDao().listar();
    final totaisDoPeriodo = await _dao.totais(
      periodo: periodo,
      tipo: tipo,
      categoriaId: categoria?.id,
    );
    final recomendacoesDoPeriodo = await RecomendacaoService().gerar(periodo);
    categorias = todasCategorias;
    // A categoria pode ter sido excluída/alterada em outra tela.
    if (categoria != null &&
        !todasCategorias.any((opcao) => opcao.id == categoria!.id)) {
      categoria = null;
    }
    totais = totaisDoPeriodo;
    recomendacoes = recomendacoesDoPeriodo;
    notifyListeners();
  }

  /// Se a data inicial passar da final, a final acompanha (e vice-versa).
  void definirInicio(DateTime data) {
    periodo = Periodo(data, data.isAfter(periodo.ate) ? data : periodo.ate);
    carregar();
  }

  void definirFim(DateTime data) {
    periodo = Periodo(data.isBefore(periodo.de) ? data : periodo.de, data);
    carregar();
  }

  void mudarCategoria(Categoria? novaCategoria) {
    categoria = novaCategoria;
    carregar();
  }

  void mudarTipo(Tipo? novoTipo) {
    tipo = novoTipo;
    if (categoria != null && novoTipo != null && categoria!.tipo != novoTipo) {
      categoria = null;
    }
    carregar();
  }

  Future<void> exportarPdf() =>
      _exportar(() => RelatorioPdfService().gerar(filtro));

  Future<void> exportarPlanilha(FormatoPlanilha formato) =>
      _exportar(() => RelatorioPlanilhaService().gerar(filtro, formato));

  /// Gera o arquivo e abre o compartilhamento do sistema. Erros sobem para a View.
  Future<void> _exportar(Future<File> Function() gerar) async {
    exportando = true;
    notifyListeners();
    try {
      final arquivo = await gerar();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(arquivo.path)], subject: 'Relatório NoBolso'),
      );
    } finally {
      exportando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(carregar);
    super.dispose();
  }
}
