/// Tipo de lançamento e de categoria. Gravado no banco como 'receita' / 'despesa'.
enum Tipo {
  receita,
  despesa;

  static Tipo deTexto(String valor) =>
      Tipo.values.firstWhere((t) => t.name == valor);

  String get rotulo => this == Tipo.receita ? 'Receita' : 'Despesa';
  String get rotuloPlural => this == Tipo.receita ? 'Receitas' : 'Despesas';
}
