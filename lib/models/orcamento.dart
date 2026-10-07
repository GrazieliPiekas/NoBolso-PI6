import 'dart:ui';

/// Orçamento mensal recorrente. `categoriaId == null` significa o orçamento geral do mês.
class Orcamento {
  final int? id;
  final int? categoriaId;
  final int limiteCentavos;

  /// Preenchidos via JOIN com categorias (nulos no orçamento geral).
  final String? categoriaNome;
  final int? categoriaCor;

  const Orcamento({
    this.id,
    this.categoriaId,
    required this.limiteCentavos,
    this.categoriaNome,
    this.categoriaCor,
  });

  bool get geral => categoriaId == null;

  String get nome => categoriaNome ?? 'Orçamento geral';

  Color get cor => Color(categoriaCor ?? 0xFF3E6A46);

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'categoria_id': categoriaId,
    'limite_centavos': limiteCentavos,
  };

  factory Orcamento.fromMap(Map<String, Object?> m) => Orcamento(
    id: m['id'] as int,
    categoriaId: m['categoria_id'] as int?,
    limiteCentavos: m['limite_centavos'] as int,
    categoriaNome: m['categoria_nome'] as String?,
    categoriaCor: m['categoria_cor'] as int?,
  );
}
