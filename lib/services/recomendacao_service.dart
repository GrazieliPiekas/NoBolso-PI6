import '../database/lancamento_dao.dart';
import '../utils/formatadores.dart';
import 'orcamento_service.dart';

enum TipoRecomendacao { alerta, dica, info, positivo }

class Recomendacao {
  final String titulo;
  final String descricao;
  final TipoRecomendacao tipo;
  const Recomendacao(this.titulo, this.descricao, this.tipo);
}

/// Dia da semana com maior gasto (0 = segunda … 6 = domingo).
class DestaqueDiaSemana {
  final int diaSemana;
  final int total;
  final double fracao;
  const DestaqueDiaSemana(this.diaSemana, this.total, this.fracao);
  String get nome => Formatadores.diasSemana[diaSemana];
}

/// Recomendações automáticas por regras fixas (RF07, decisão 10).
class RecomendacaoService {
  final LancamentoDao _lancamentos;
  final OrcamentoService _orcamentos;

  RecomendacaoService({
    LancamentoDao? lancamentos,
    OrcamentoService? orcamentos,
  }) : _lancamentos = lancamentos ?? LancamentoDao(),
       _orcamentos = orcamentos ?? OrcamentoService();

  Future<List<Recomendacao>> gerar(Periodo periodo, {DateTime? hoje}) async {
    final agora = hoje ?? DateTime.now();
    return aplicarRegras(
      totais: await _lancamentos.totais(periodo: periodo),
      porCategoria: await _lancamentos.despesasPorCategoria(periodo),
      porDia: await _lancamentos.totaisPorDia(periodo),
      orcamentosDoMes: (await _orcamentos.resumo(agora)).categorias,
    );
  }

  /// Regras puras (sem banco), fáceis de testar.
  static List<Recomendacao> aplicarRegras({
    required Totais totais,
    required List<TotalCategoria> porCategoria,
    required Map<String, (int, int)> porDia,
    required List<StatusOrcamento> orcamentosDoMes,
  }) {
    final r = <Recomendacao>[];

    // Regra 4: despesas maiores que receitas.
    if (totais.despesas > totais.receitas && totais.despesas > 0) {
      r.add(
        Recomendacao(
          'Despesas acima das receitas',
          'Você gastou ${Formatadores.moeda(totais.despesas - totais.receitas)} '
              'a mais do que recebeu. Rever os gastos variáveis pode ajudar.',
          TipoRecomendacao.alerta,
        ),
      );
    }

    // Regra 2: categorias acima de 80% do orçamento do mês.
    final apertados =
        orcamentosDoMes.where((s) => s.percentual >= 0.8).toList()
          ..sort((a, b) => b.percentual.compareTo(a.percentual));
    for (final s in apertados) {
      final p = (s.percentual * 100).round();
      r.add(
        Recomendacao(
          '${s.orcamento.nome} chegou a $p% do limite',
          s.disponivel >= 0
              ? 'Restam ${Formatadores.moeda(s.disponivel)} até o fim do mês.'
              : 'Passou ${Formatadores.moeda(-s.disponivel)} do limite de '
                    '${Formatadores.moeda(s.limite)}. Que tal segurar um pouco?',
          TipoRecomendacao.alerta,
        ),
      );
    }

    // Regra 1: categoria com maior gasto.
    if (porCategoria.isNotEmpty && totais.despesas > 0) {
      final maior = porCategoria.first;
      final p = (maior.totalCentavos * 100 / totais.despesas).round();
      r.add(
        Recomendacao(
          'Maior gasto: ${maior.nome}',
          '${Formatadores.moeda(maior.totalCentavos)}, $p% das suas despesas no período.',
          TipoRecomendacao.dica,
        ),
      );
    }

    // Regra 3: dia da semana com maior gasto.
    final dia = diaMaisGasto(porDia);
    if (dia != null) {
      r.add(
        Recomendacao(
          '${dia.nome} concentra ${(dia.fracao * 100).round()}% dos gastos',
          'Planejar as compras desse dia ajuda a controlar o mês.',
          TipoRecomendacao.info,
        ),
      );
    }

    // Reforço positivo quando sobra dinheiro.
    if (totais.saldo > 0 && totais.receitas > 0) {
      final guardar = (totais.saldo * 0.1).round();
      r.add(
        Recomendacao(
          'Guarde ${Formatadores.moedaCurta(guardar)}',
          'É 10% do seu saldo positivo no período. Bom trabalho!',
          TipoRecomendacao.positivo,
        ),
      );
    }

    if (r.isEmpty) {
      r.add(
        const Recomendacao(
          'Ainda sem recomendações',
          'Registre alguns lançamentos para receber dicas sobre seus gastos.',
          TipoRecomendacao.info,
        ),
      );
    }
    return r;
  }

  static DestaqueDiaSemana? diaMaisGasto(Map<String, (int, int)> porDia) {
    final somas = List<int>.filled(7, 0);
    var total = 0;
    porDia.forEach((data, v) {
      final d = Formatadores.dataDoDb(data);
      somas[d.weekday - 1] += v.$2;
      total += v.$2;
    });
    if (total == 0) return null;
    var idx = 0;
    for (var i = 1; i < 7; i++) {
      if (somas[i] > somas[idx]) idx = i;
    }
    return DestaqueDiaSemana(idx, somas[idx], somas[idx] / total);
  }
}
