import '../database/lancamento_dao.dart';
import '../utils/formatadores.dart';
import 'orcamento_service.dart';

/// Tipo da dica (muda a cor do cartão na tela).
enum TipoRecomendacao { alerta, dica, info, positivo }

/// Uma dica mostrada em Relatórios.
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

  /// Aplica as 4 regras e devolve as dicas do período.
  /// Se nenhuma regra disparar, devolve uma mensagem positiva.
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
    final recomendacoes = <Recomendacao>[];

    // Regra 4: despesas maiores que receitas.
    if (totais.despesas > totais.receitas && totais.despesas > 0) {
      recomendacoes.add(
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
        orcamentosDoMes.where((status) => status.percentual >= 0.8).toList()
          ..sort(
            (primeiro, segundo) =>
                segundo.percentual.compareTo(primeiro.percentual),
          );
    for (final status in apertados) {
      final porcentagem = (status.percentual * 100).round();
      recomendacoes.add(
        Recomendacao(
          '${status.orcamento.nome} chegou a $porcentagem% do limite',
          status.disponivel >= 0
              ? 'Restam ${Formatadores.moeda(status.disponivel)} até o fim do mês.'
              : 'Passou ${Formatadores.moeda(-status.disponivel)} do limite de '
                    '${Formatadores.moeda(status.limite)}. Que tal segurar um pouco?',
          TipoRecomendacao.alerta,
        ),
      );
    }

    // Regra 1: categoria com maior gasto.
    if (porCategoria.isNotEmpty && totais.despesas > 0) {
      final maior = porCategoria.first;
      final porcentagem = (maior.totalCentavos * 100 / totais.despesas).round();
      recomendacoes.add(
        Recomendacao(
          'Maior gasto: ${maior.nome}',
          '${Formatadores.moeda(maior.totalCentavos)}, $porcentagem% das suas despesas no período.',
          TipoRecomendacao.dica,
        ),
      );
    }

    // Regra 3: dia da semana com maior gasto.
    final dia = diaMaisGasto(porDia);
    if (dia != null) {
      recomendacoes.add(
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
      recomendacoes.add(
        Recomendacao(
          'Guarde ${Formatadores.moedaCurta(guardar)}',
          'É 10% do seu saldo positivo no período. Bom trabalho!',
          TipoRecomendacao.positivo,
        ),
      );
    }

    if (recomendacoes.isEmpty) {
      recomendacoes.add(
        const Recomendacao(
          'Ainda sem recomendações',
          'Registre alguns lançamentos para receber dicas sobre seus gastos.',
          TipoRecomendacao.info,
        ),
      );
    }
    return recomendacoes;
  }

  /// Soma as despesas por dia da semana e devolve o dia que mais gastou.
  static DestaqueDiaSemana? diaMaisGasto(Map<String, (int, int)> porDia) {
    final somas = List<int>.filled(7, 0);
    var total = 0;
    porDia.forEach((data, totaisDoDia) {
      final dataDoGasto = Formatadores.dataDoDb(data);
      somas[dataDoGasto.weekday - 1] += totaisDoDia.$2;
      total += totaisDoDia.$2;
    });
    if (total == 0) return null;
    var idx = 0;
    for (var i = 1; i < 7; i++) {
      if (somas[i] > somas[idx]) idx = i;
    }
    return DestaqueDiaSemana(idx, somas[idx], somas[idx] / total);
  }
}
