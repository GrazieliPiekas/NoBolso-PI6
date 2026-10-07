import 'dart:ui';

import 'tipo.dart';

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

  factory Categoria.fromMap(Map<String, Object?> m) => Categoria(
    id: m['id'] as int,
    nome: m['nome'] as String,
    tipo: Tipo.deTexto(m['tipo'] as String),
    cor: m['cor'] as int,
  );

  Categoria copyWith({int? id, String? nome, Tipo? tipo, int? cor}) =>
      Categoria(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        tipo: tipo ?? this.tipo,
        cor: cor ?? this.cor,
      );
}
