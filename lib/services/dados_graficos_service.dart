import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../utils/formatadores.dart';
import 'recomendacao_service.dart';

/// Filtro da tela de Análise.
enum FiltroAnalise {
  mes('Mês'),
  trimestre('Trimestre'),
  ano('Ano');

  final String rotulo;
  const FiltroAnalise(this.rotulo);
}

/// Tudo que a tela de Início precisa, buscado de uma vez.
class DadosInicio {
  final Totais totais;
  final List<TotalCategoria> porCategoria;
  final List<Lancamento> ultimos;
  const DadosInicio(this.totais, this.porCategoria, this.ultimos);
}

/// Série do gráfico de linha: um valor e um rótulo (pode ser vazio) por ponto.
class SerieLinha {
  final List<double> valores;
  final List<String> rotulos;
  const SerieLinha(this.valores, this.rotulos);
  bool get vazia => valores.every((valor) => valor == 0);
}

/// Matriz do mapa de calor: linhas × 7 dias da semana. `null` = célula fora do período.
class MatrizCalor {
  final List<String> rotulosLinhas;
  final List<List<double?>> valores;
  const MatrizCalor(this.rotulosLinhas, this.valores);
  double get maximo => valores
      .expand((linha) => linha)
      .whereType<double>()
      .fold(0.0, (maior, valor) => valor > maior ? valor : maior);
}

/// Tudo que a tela de Análise precisa: série da linha, mapa de calor e destaques.
class DadosAnalise {
  final Periodo periodo;
  final SerieLinha saldo;
  final MatrizCalor calor;
  final DestaqueDiaSemana? destaque;
  final String? maiorCategoria;
  final Totais totais;
  const DadosAnalise(
    this.periodo,
    this.saldo,
    this.calor,
    this.destaque,
    this.maiorCategoria,
    this.totais,
  );
}

/// Prepara os números que os painters desenham. Nenhum desenho acontece aqui.
class DadosGraficosService {
  final LancamentoDao _dao;
  DadosGraficosService([LancamentoDao? dao]) : _dao = dao ?? LancamentoDao();

  /// Monta os dados do Início para o mês informado.
  Future<DadosInicio> inicio(DateTime mes) async {
    final periodo = Periodo.mes(mes);
    return DadosInicio(
      await _dao.totais(periodo: periodo),
      await _dao.despesasPorCategoria(periodo),
      await _dao.listar(limite: 5),
    );
  }

  /// Mês = mês atual; Trimestre = últimos 3 meses; Ano = últimos 12 meses.
  static Periodo periodoDoFiltro(FiltroAnalise filtro, DateTime hoje) =>
      switch (filtro) {
        FiltroAnalise.mes => Periodo.mes(hoje),
        FiltroAnalise.trimestre => Periodo.ultimosMeses(hoje, 3),
        FiltroAnalise.ano => Periodo.ultimosMeses(hoje, 12),
      };

  /// Monta os dados da Análise. `hoje` só é passado nos testes.
  Future<DadosAnalise> analise(FiltroAnalise filtro, {DateTime? hoje}) async {
    final agora = hoje ?? DateTime.now();
    final periodo = periodoDoFiltro(filtro, agora);
    final porDia = await _dao.totaisPorDia(periodo);
    final porCategoria = await _dao.despesasPorCategoria(periodo);
    return DadosAnalise(
      periodo,
      serieSaldo(filtro, periodo, porDia, agora),
      matrizCalor(filtro, periodo, porDia),
      RecomendacaoService.diaMaisGasto(porDia),
      porCategoria.isEmpty ? null : porCategoria.first.nome,
      await _dao.totais(periodo: periodo),
    );
  }

  /// Saldo acumulado ao longo do período.
  /// Mês: um ponto por dia (até hoje). Trimestre: por semana. Ano: por mês.
  static SerieLinha serieSaldo(
    FiltroAnalise filtro,
    Periodo periodo,
    Map<String, (int, int)> porDia,
    DateTime hoje,
  ) {
    final fim = hoje.isBefore(periodo.ate) && !hoje.isBefore(periodo.de)
        ? DateTime(hoje.year, hoje.month, hoje.day)
        : periodo.ate;

    // Limites (fim exclusivo) de cada balde.
    final inicios = <DateTime>[];
    final rotulos = <String>[];
    switch (filtro) {
      case FiltroAnalise.mes:
        for (
          var dia = periodo.de;
          !dia.isAfter(fim);
          dia = dia.add(const Duration(days: 1))
        ) {
          inicios.add(dia);
          rotulos.add(dia.day == 1 || dia.day % 5 == 0 ? '${dia.day}' : '');
        }
      case FiltroAnalise.trimestre:
        for (
          var dia = periodo.de;
          !dia.isAfter(fim);
          dia = dia.add(const Duration(days: 7))
        ) {
          inicios.add(dia);
          rotulos.add(dia.day <= 7 ? Formatadores.mesAbreviado(dia) : '');
        }
      case FiltroAnalise.ano:
        for (
          var dia = periodo.de;
          !dia.isAfter(fim);
          dia = DateTime(dia.year, dia.month + 1, 1)
        ) {
          inicios.add(dia);
          rotulos.add(Formatadores.mesAbreviado(dia));
        }
    }

    final valores = List<double>.filled(inicios.length, 0);
    porDia.forEach((data, totaisDoDia) {
      final dia = Formatadores.dataDoDb(data);
      if (dia.isAfter(fim)) return;
      var i = inicios.length - 1;
      while (i > 0 && dia.isBefore(inicios[i])) {
        i--;
      }
      valores[i] += (totaisDoDia.$1 - totaisDoDia.$2) / 100;
    });
    for (var i = 1; i < valores.length; i++) {
      valores[i] += valores[i - 1];
    }
    return SerieLinha(valores, rotulos);
  }

  /// Mês: linhas = semanas do mês. Trimestre/Ano: linhas = meses.
  /// Colunas = dias da semana (segunda a domingo). Valor = despesas em reais.
  static MatrizCalor matrizCalor(
    FiltroAnalise filtro,
    Periodo periodo,
    Map<String, (int, int)> porDia,
  ) {
    if (filtro == FiltroAnalise.mes) {
      final deslocamento = periodo.de.weekday - 1;
      final linhas = ((deslocamento + periodo.dias) / 7).ceil();
      final matriz = List.generate(
        linhas,
        (_) => List<double?>.filled(7, null),
      );
      for (var i = 0; i < periodo.dias; i++) {
        final pos = deslocamento + i;
        matriz[pos ~/ 7][pos % 7] = 0;
      }
      porDia.forEach((data, totaisDoDia) {
        final dia = Formatadores.dataDoDb(data);
        final pos = deslocamento + dia.day - 1;
        matriz[pos ~/ 7][pos % 7] = totaisDoDia.$2 / 100;
      });
      return MatrizCalor(List.generate(linhas, (i) => 'Sem ${i + 1}'), matriz);
    }

    final meses = <DateTime>[];
    for (
      var dia = periodo.de;
      !dia.isAfter(periodo.ate);
      dia = DateTime(dia.year, dia.month + 1, 1)
    ) {
      meses.add(dia);
    }
    final matriz = List.generate(
      meses.length,
      (_) => List<double?>.filled(7, 0),
    );
    porDia.forEach((data, totaisDoDia) {
      final dia = Formatadores.dataDoDb(data);
      final linha =
          (dia.year - periodo.de.year) * 12 + dia.month - periodo.de.month;
      matriz[linha][dia.weekday - 1] =
          matriz[linha][dia.weekday - 1]! + totaisDoDia.$2 / 100;
    });
    return MatrizCalor(meses.map(Formatadores.mesAbreviado).toList(), matriz);
  }
}
