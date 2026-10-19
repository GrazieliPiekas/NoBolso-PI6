/// Tipo de lançamento e de categoria. Gravado no banco como 'receita' / 'despesa'.
enum Tipo {
  receita,
  despesa;

  /// Converte o texto salvo no banco ('receita'/'despesa') de volta para o enum.
  static Tipo deTexto(String valor) =>
      Tipo.values.firstWhere((tipo) => tipo.name == valor);

  String get rotulo => this == Tipo.receita ? 'Receita' : 'Despesa';
  String get rotuloPlural => this == Tipo.receita ? 'Receitas' : 'Despesas';
}
