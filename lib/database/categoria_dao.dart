import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';
import '../models/tipo.dart';
import 'database_helper.dart';

/// Lançada ao tentar excluir uma categoria com lançamentos ou orçamento (decisão 6).
class CategoriaEmUsoException implements Exception {
  final String mensagem;
  CategoriaEmUsoException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Lançada quando já existe uma categoria com o mesmo nome e tipo.
class CategoriaDuplicadaException implements Exception {
  @override
  String toString() => 'Já existe uma categoria com esse nome.';
}

/// DAO das categorias: todo SQL da tabela `categorias` fica aqui,
/// assim as telas e ViewModels nunca escrevem SQL.
class CategoriaDao {
  final DatabaseHelper _helper;
  CategoriaDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  /// Lista as categorias (opcionalmente só de um tipo).
  /// "Outros" sempre vai pro final da lista.
  Future<List<Categoria>> listar({Tipo? tipo}) async {
    final db = await _helper.database;
    final linhas = await db.query(
      'categorias',
      where: tipo == null ? null : 'tipo = ?',
      whereArgs: tipo == null ? null : [tipo.name],
      orderBy: "tipo DESC, nome = 'Outros', nome COLLATE NOCASE",
    );
    return linhas.map(Categoria.fromMap).toList();
  }

  Future<Categoria?> buscar(int id) async {
    final db = await _helper.database;
    final linhas = await db.query(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
    return linhas.isEmpty ? null : Categoria.fromMap(linhas.first);
  }

  /// Insere e devolve o id gerado. Nome repetido no mesmo tipo vira
  /// [CategoriaDuplicadaException] (o banco tem UNIQUE(nome, tipo)).
  Future<int> inserir(Categoria categoria) async {
    final db = await _helper.database;
    try {
      return await db.insert('categorias', categoria.toMap()..remove('id'));
    } on DatabaseException catch (erro) {
      if (erro.isUniqueConstraintError()) throw CategoriaDuplicadaException();
      rethrow;
    }
  }

  /// Atualiza nome, tipo e cor. Não deixa trocar o tipo se a categoria
  /// já tem lançamentos, senão uma despesa ia virar receita do nada.
  Future<void> atualizar(Categoria categoria) async {
    final db = await _helper.database;
    if (categoria.tipo != (await buscar(categoria.id!))?.tipo &&
        await emUso(categoria.id!)) {
      throw CategoriaEmUsoException(
        'Não dá para trocar o tipo de uma categoria que já tem lançamentos.',
      );
    }
    try {
      await db.update(
        'categorias',
        categoria.toMap(),
        where: 'id = ?',
        whereArgs: [categoria.id],
      );
    } on DatabaseException catch (erro) {
      if (erro.isUniqueConstraintError()) throw CategoriaDuplicadaException();
      rethrow;
    }
  }

  /// true se a categoria tem algum lançamento ou orçamento ligado a ela.
  Future<bool> emUso(int id) async {
    final db = await _helper.database;
    final resultado = await db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM lancamentos WHERE categoria_id = ?) AS l, '
      '(SELECT COUNT(*) FROM orcamentos WHERE categoria_id = ?) AS o',
      [id, id],
    );
    return (resultado.first['l'] as int) > 0 ||
        (resultado.first['o'] as int) > 0;
  }

  /// Bloqueia a exclusão se a categoria estiver em uso, com mensagem clara.
  Future<void> excluir(int id) async {
    final db = await _helper.database;
    final resultado = await db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM lancamentos WHERE categoria_id = ?) AS l, '
      '(SELECT COUNT(*) FROM orcamentos WHERE categoria_id = ?) AS o',
      [id, id],
    );
    final lancamentos = resultado.first['l'] as int;
    final orcamentos = resultado.first['o'] as int;
    if (lancamentos > 0) {
      throw CategoriaEmUsoException(
        'Esta categoria tem $lancamentos lançamento${lancamentos == 1 ? '' : 's'}. '
        'Mova ou exclua esses lançamentos antes de apagá-la.',
      );
    }
    if (orcamentos > 0) {
      throw CategoriaEmUsoException(
        'Esta categoria tem um orçamento. Remova o orçamento antes de apagá-la.',
      );
    }
    await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}
