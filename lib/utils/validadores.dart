import 'formatadores.dart';

/// Validações feitas antes de salvar (RF11). Retornam a mensagem de erro ou null.
class Validadores {
  Validadores._();

  /// Limite de segurança: R$ 10 milhões por lançamento.
  static const valorMaximoCentavos = 1000000000;

  static String? valor(String? texto) {
    if (texto == null || texto.trim().isEmpty) return 'Informe um valor';
    final c = Formatadores.centavosDeTexto(texto);
    if (c == null) return 'Valor inválido';
    if (c <= 0) return 'O valor precisa ser maior que zero';
    if (c > valorMaximoCentavos) return 'Valor muito alto';
    return null;
  }

  static String? categoria(int? categoriaId) =>
      categoriaId == null ? 'Escolha uma categoria' : null;

  static String? descricao(String? texto) {
    final t = texto?.trim() ?? '';
    if (t.isEmpty) return 'Escreva uma descrição curta';
    if (t.length > 80) return 'Use no máximo 80 caracteres';
    return null;
  }

  static String? nomeCategoria(String? texto) {
    final t = texto?.trim() ?? '';
    if (t.isEmpty) return 'Dê um nome à categoria';
    if (t.length > 30) return 'Use no máximo 30 caracteres';
    return null;
  }
}
