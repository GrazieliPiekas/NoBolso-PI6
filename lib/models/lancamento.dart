import 'dart:ui';

import '../utils/formatadores.dart';
import 'tipo.dart';

/// Uma receita ou despesa registrada pelo usuário.
class Lancamento {
  final int? id;
  final String descricao;

  /// Valor em centavos (INTEGER) para evitar erro de arredondamento.
  final int valorCentavos;
  final Tipo tipo;
  final int categoriaId;
  final DateTime data;

  /// Receita ou despesa fixa (repete todo mês). BOOLEAN do SQLite: INTEGER 0/1.
  final bool fixo;

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
    this.fixo = false,
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
    'fixo': fixo ? 1 : 0,
  };

  factory Lancamento.fromMap(Map<String, Object?> mapa) => Lancamento(
    id: mapa['id'] as int,
    descricao: mapa['descricao'] as String,
    valorCentavos: mapa['valor_centavos'] as int,
    tipo: Tipo.deTexto(mapa['tipo'] as String),
    categoriaId: mapa['categoria_id'] as int,
    data: Formatadores.dataDoDb(mapa['data'] as String),
    fixo: (mapa['fixo'] as int? ?? 0) == 1,
    categoriaNome: mapa['categoria_nome'] as String?,
    categoriaCor: mapa['categoria_cor'] as int?,
  );
}
