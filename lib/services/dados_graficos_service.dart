import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../utils/formatadores.dart';
import 'recomendacao_service.dart';

enum FiltroAnalise {
  mes('Mês'),
  trimestre('Trimestre'),
  ano('Ano');

  final String rotulo;
  const FiltroAnalise(this.rotulo);
}

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
  bool get vazia => valores.every((v) => v == 0);
}

/// Matriz do mapa de calor: linhas × 7 dias da semana. `null` = célula fora do período.
class MatrizCalor {
  final List<String> rotulosLinhas;
  final List<List<double?>> valores;
  const MatrizCalor(this.rotulosLinhas, this.valores);
  double get maximo => valores
      .expand((l) => l)
      .whereType<double>()
      .fold(0.0, (m, v) => v > m ? v : m);
}

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

  Future<DadosInicio> inicio(DateTime mes) async {
    final p = Periodo.mes(mes);
    return DadosInicio(
      await _dao.totais(periodo: p),
      await _dao.despesasPorCategoria(p),
      await _dao.listar(limite: 5),
    );
  }

  static Periodo periodoDoFiltro(FiltroAnalise f, DateTime hoje) =>
      switch (f) {
        FiltroAnalise.mes => Periodo.mes(hoje),
        FiltroAnalise.trimestre => Periodo.ultimosMeses(hoje, 3),
        FiltroAnalise.ano => Periodo.ultimosMeses(hoje, 12),
      };

  Future<DadosAnalise> analise(FiltroAnalise f, {DateTime? hoje}) async {
    final agora = hoje ?? DateTime.now();
    final p = periodoDoFiltro(f, agora);
    final porDia = await _dao.totaisPorDia(p);
    final porCategoria = await _dao.despesasPorCategoria(p);
    return DadosAnalise(
      p,
      serieSaldo(f, p, porDia, agora),
      matrizCalor(f, p, porDia),
      RecomendacaoService.diaMaisGasto(porDia),
      porCategoria.isEmpty ? null : porCategoria.first.nome,
      await _dao.totais(periodo: p),
    );
  }

  /// Saldo acumulado ao longo do período.
  /// Mês: um ponto por dia (até hoje). Trimestre: por semana. Ano: por mês.
  static SerieLinha serieSaldo(
    FiltroAnalise f,
    Periodo p,
    Map<String, (int, int)> porDia,
    DateTime hoje,
  ) {
    final fim = hoje.isBefore(p.ate) && !hoje.isBefore(p.de)
        ? DateTime(hoje.year, hoje.month, hoje.day)
        : p.ate;

    // Limites (fim exclusivo) de cada balde.
    final inicios = <DateTime>[];
    final rotulos = <String>[];
    switch (f) {
      case FiltroAnalise.mes:
        for (var d = p.de; !d.isAfter(fim); d = d.add(const Duration(days: 1))) {
          inicios.add(d);
          rotulos.add(d.day == 1 || d.day % 5 == 0 ? '${d.day}' : '');
        }
      case FiltroAnalise.trimestre:
        for (var d = p.de; !d.isAfter(fim); d = d.add(const Duration(days: 7))) {
          inicios.add(d);
          rotulos.add(
            d.day <= 7 ? Formatadores.mesAbreviado(d) : '',
          );
        }
      case FiltroAnalise.ano:
        for (
          var d = p.de;
          !d.isAfter(fim);
          d = DateTime(d.year, d.month + 1, 1)
        ) {
          inicios.add(d);
          rotulos.add(Formatadores.mesAbreviado(d));
        }
    }

    final valores = List<double>.filled(inicios.length, 0);
    porDia.forEach((data, v) {
      final d = Formatadores.dataDoDb(data);
      if (d.isAfter(fim)) return;
      var i = inicios.length - 1;
      while (i > 0 && d.isBefore(inicios[i])) {
        i--;
      }
      valores[i] += (v.$1 - v.$2) / 100;
    });
    for (var i = 1; i < valores.length; i++) {
      valores[i] += valores[i - 1];
    }
    return SerieLinha(valores, rotulos);
  }

  /// Mês: linhas = semanas do mês. Trimestre/Ano: linhas = meses.
  /// Colunas = dias da semana (segunda a domingo). Valor = despesas em reais.
  static MatrizCalor matrizCalor(
    FiltroAnalise f,
    Periodo p,
    Map<String, (int, int)> porDia,
  ) {
    if (f == FiltroAnalise.mes) {
      final deslocamento = p.de.weekday - 1;
      final linhas = ((deslocamento + p.dias) / 7).ceil();
      final m = List.generate(linhas, (_) => List<double?>.filled(7, null));
      for (var i = 0; i < p.dias; i++) {
        final pos = deslocamento + i;
        m[pos ~/ 7][pos % 7] = 0;
      }
      porDia.forEach((data, v) {
        final d = Formatadores.dataDoDb(data);
        final pos = deslocamento + d.day - 1;
        m[pos ~/ 7][pos % 7] = v.$2 / 100;
      });
      return MatrizCalor(
        List.generate(linhas, (i) => 'Sem ${i + 1}'),
        m,
      );
    }

    final meses = <DateTime>[];
    for (var d = p.de; !d.isAfter(p.ate); d = DateTime(d.year, d.month + 1, 1)) {
      meses.add(d);
    }
    final m = List.generate(meses.length, (_) => List<double?>.filled(7, 0));
    porDia.forEach((data, v) {
      final d = Formatadores.dataDoDb(data);
      final linha = (d.year - p.de.year) * 12 + d.month - p.de.month;
      m[linha][d.weekday - 1] = m[linha][d.weekday - 1]! + v.$2 / 100;
    });
    return MatrizCalor(meses.map(Formatadores.mesAbreviado).toList(), m);
  }
}
