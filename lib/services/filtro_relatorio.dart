import '../models/tipo.dart';
import '../utils/formatadores.dart';

/// Filtros escolhidos na tela de Relatórios; os arquivos exportados respeitam os mesmos (RF08).
class FiltroRelatorio {
  final Periodo periodo;
  final Tipo? tipo;
  final int? categoriaId;
  final String? categoriaNome;

  const FiltroRelatorio({
    required this.periodo,
    this.tipo,
    this.categoriaId,
    this.categoriaNome,
  });

  String get descricaoPeriodo =>
      '${Formatadores.dataCurta(periodo.de)} a ${Formatadores.dataCurta(periodo.ate)}';
  String get descricaoCategoria => categoriaNome ?? 'Todas as categorias';
  String get descricaoTipo => tipo?.rotuloPlural ?? 'Receitas e despesas';

  /// Base do nome do arquivo: nobolso_2026-09-01_2026-09-30.
  String get nomeArquivo => 'nobolso_${periodo.deDb}_${periodo.ateDb}';
}
