import 'formatadores.dart';

/// Validações feitas antes de salvar (RF11). Retornam a mensagem de erro ou null.
class Validadores {
  Validadores._();

  /// Limite de segurança: R$ 10 milhões por lançamento.
  static const valorMaximoCentavos = 1000000000;

  /// Valor obrigatório, maior que zero e até R$ 10 milhões.
  static String? valor(String? texto) {
    if (texto == null || texto.trim().isEmpty) return 'Informe um valor';
    final centavos = Formatadores.centavosDeTexto(texto);
    if (centavos == null) return 'Valor inválido';
    if (centavos <= 0) return 'O valor precisa ser maior que zero';
    if (centavos > valorMaximoCentavos) return 'Valor muito alto';
    return null;
  }

  /// Categoria obrigatória.
  static String? categoria(int? categoriaId) =>
      categoriaId == null ? 'Escolha uma categoria' : null;

  /// Descrição obrigatória e com no máximo 80 caracteres.
  static String? descricao(String? texto) {
    final limpo = texto?.trim() ?? '';
    if (limpo.isEmpty) return 'Escreva uma descrição curta';
    if (limpo.length > 80) return 'Use no máximo 80 caracteres';
    return null;
  }

  /// Nome da categoria obrigatório e com no máximo 30 caracteres.
  static String? nomeCategoria(String? texto) {
    final limpo = texto?.trim() ?? '';
    if (limpo.isEmpty) return 'Dê um nome à categoria';
    if (limpo.length > 30) return 'Use no máximo 30 caracteres';
    return null;
  }
}
