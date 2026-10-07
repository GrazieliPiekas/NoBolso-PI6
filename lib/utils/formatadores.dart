import 'package:intl/intl.dart';

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

  static String dataParaDb(DateTime d) => _db.format(d);
  static DateTime dataDoDb(String s) => DateTime.parse(s);
  static String dataCurta(DateTime d) => _curta.format(d);
  static String dataLonga(DateTime d) => _longa.format(d);

  /// "Setembro 2026".
  static String mesAno(DateTime d) => capitalizar(_mes.format(d));

  /// "Set".
  static String mesAbreviado(DateTime d) =>
      capitalizar(_mesAbrev.format(d).replaceAll('.', ''));

  /// Referência do mês usada em alertas_enviados: "2026-09".
  static String referenciaMes(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static String capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Converte o texto digitado ("186,40", "1.234,5", "50") em centavos.
  /// Retorna null se não for um número válido.
  static int? centavosDeTexto(String texto) {
    var t = texto.trim().replaceAll(RegExp(r'[R$\s]'), '');
    if (t.isEmpty) return null;
    t = t.replaceAll('.', '').replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return (v * 100).round();
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

  factory Periodo.mes(DateTime d) =>
      Periodo(DateTime(d.year, d.month, 1), DateTime(d.year, d.month + 1, 0));

  /// Os últimos [n] meses terminando no mês de [d] (inclusive).
  factory Periodo.ultimosMeses(DateTime d, int n) => Periodo(
    DateTime(d.year, d.month - n + 1, 1),
    DateTime(d.year, d.month + 1, 0),
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
