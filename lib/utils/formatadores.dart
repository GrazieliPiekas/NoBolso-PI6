import 'package:intl/intl.dart';

/// Funções para formatar dinheiro e datas do jeito brasileiro.
class Formatadores {
  Formatadores._();

  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final _moedaSemCentavos = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 0,
  );
  static final _numero = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );
  static final _db = DateFormat('yyyy-MM-dd');
  static final _curta = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _longa = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');
  static final _mes = DateFormat('MMMM yyyy', 'pt_BR');
  static final _mesAbrev = DateFormat('MMM', 'pt_BR');

  /// 171965 → "R$ 1.719,65" (com espaço normal, não o NBSP do intl).
  static String moeda(int centavos) =>
      _moeda.format(centavos / 100).replaceAll(' ', ' ');

  /// 171965 → "R$ 1.720" (para rótulos curtos dos gráficos).
  static String moedaCurta(int centavos) =>
      _moedaSemCentavos.format(centavos / 100).replaceAll(' ', ' ');

  /// Valor com sinal, como na lista: "- R$ 186,40" / "+ R$ 4.200,00".
  static String moedaComSinal(int centavos, {required bool positivo}) =>
      '${positivo ? '+' : '-'} ${moeda(centavos.abs())}';

  /// 171965 → "1.719,65" (sem símbolo; usado no CSV).
  static String numero(int centavos) => _numero.format(centavos / 100);

  /// Data no formato do banco: "2026-10-19" (permite filtrar com BETWEEN).
  static String dataParaDb(DateTime data) => _db.format(data);

  /// Volta do texto do banco para DateTime.
  static DateTime dataDoDb(String texto) => DateTime.parse(texto);

  /// "19/10/2026"
  static String dataCurta(DateTime data) => _curta.format(data);

  /// "19 de outubro de 2026"
  static String dataLonga(DateTime data) => _longa.format(data);

  /// "Setembro 2026".
  static String mesAno(DateTime data) => capitalizar(_mes.format(data));

  /// "Set".
  static String mesAbreviado(DateTime data) =>
      capitalizar(_mesAbrev.format(data).replaceAll('.', ''));

  /// Referência do mês usada em alertas_enviados: "2026-09".
  static String referenciaMes(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$ano-$mes';
  }

  static String capitalizar(String texto) =>
      texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

  /// Converte o texto digitado ("186,40", "1.234,5", "50") em centavos.
  /// Retorna null se não for um número válido.
  static int? centavosDeTexto(String texto) {
    var limpo = texto.trim().replaceAll(RegExp(r'[R$\s]'), '');
    if (limpo.isEmpty) return null;
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(limpo);
    if (valor == null || valor.isNaN || valor.isInfinite) return null;
    return (valor * 100).round();
  }

  static const diasSemanaCurtos = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  static const diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
}

/// Intervalo fechado de datas [de, ate].
class Periodo {
  final DateTime de;
  final DateTime ate;

  Periodo(DateTime de, DateTime ate)
    : de = DateTime(de.year, de.month, de.day),
      ate = DateTime(ate.year, ate.month, ate.day);

  factory Periodo.mes(DateTime data) => Periodo(
    DateTime(data.year, data.month, 1),
    DateTime(data.year, data.month + 1, 0),
  );

  /// Os últimos [n] meses terminando no mês de [d] (inclusive).
  factory Periodo.ultimosMeses(DateTime data, int quantidadeMeses) => Periodo(
    DateTime(data.year, data.month - quantidadeMeses + 1, 1),
    DateTime(data.year, data.month + 1, 0),
  );

  String get deDb => Formatadores.dataParaDb(de);
  String get ateDb => Formatadores.dataParaDb(ate);

  int get dias => ate.difference(de).inDays + 1;

  @override
  bool operator ==(Object other) =>
      other is Periodo && other.de == de && other.ate == ate;

  @override
  int get hashCode => Object.hash(de, ate);
}
