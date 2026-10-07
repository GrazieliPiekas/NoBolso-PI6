import 'dart:ui';

import '../utils/formatadores.dart';
import 'tipo.dart';

class Lancamento {
  final int? id;
  final String descricao;

  /// Valor em centavos (INTEGER) para evitar erro de arredondamento.
  final int valorCentavos;
  final Tipo tipo;
  final int categoriaId;
  final DateTime data;

  /// Preenchidos quando a consulta faz JOIN com categorias.
  final String? categoriaNome;
  final int? categoriaCor;

  const Lancamento({
    this.id,
    required this.descricao,
    required this.valorCentavos,
    required this.tipo,
    required this.categoriaId,
    required this.data,
    this.categoriaNome,
    this.categoriaCor,
  });

  Color get corCategoria => Color(categoriaCor ?? 0xFF8A8A7A);

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'descricao': descricao,
    'valor_centavos': valorCentavos,
    'tipo': tipo.name,
    'categoria_id': categoriaId,
    'data': Formatadores.dataParaDb(data),
  };

  factory Lancamento.fromMap(Map<String, Object?> m) => Lancamento(
    id: m['id'] as int,
    descricao: m['descricao'] as String,
    valorCentavos: m['valor_centavos'] as int,
    tipo: Tipo.deTexto(m['tipo'] as String),
    categoriaId: m['categoria_id'] as int,
    data: Formatadores.dataDoDb(m['data'] as String),
    categoriaNome: m['categoria_nome'] as String?,
    categoriaCor: m['categoria_cor'] as int?,
  );
}
