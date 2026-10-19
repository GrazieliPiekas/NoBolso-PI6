import 'dart:ui';

import 'tipo.dart';

/// Categoria de receita ou despesa (ex.: Alimentação, Salário).
class Categoria {
  final int? id;
  final String nome;
  final Tipo tipo;

  /// Cor ARGB guardada como INTEGER.
  final int cor;

  const Categoria({
    this.id,
    required this.nome,
    required this.tipo,
    required this.cor,
  });

  Color get color => Color(cor);

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'nome': nome,
    'tipo': tipo.name,
    'cor': cor,
  };

  factory Categoria.fromMap(Map<String, Object?> mapa) => Categoria(
    id: mapa['id'] as int,
    nome: mapa['nome'] as String,
    tipo: Tipo.deTexto(mapa['tipo'] as String),
    cor: mapa['cor'] as int,
  );

  /// Cria uma cópia mudando só alguns campos (o model é imutável).
  Categoria copyWith({int? id, String? nome, Tipo? tipo, int? cor}) =>
      Categoria(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        tipo: tipo ?? this.tipo,
        cor: cor ?? this.cor,
      );
}
