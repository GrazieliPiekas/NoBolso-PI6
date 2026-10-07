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

class CategoriaDao {
  final DatabaseHelper _helper;
  CategoriaDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

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
    final l = await db.query('categorias', where: 'id = ?', whereArgs: [id]);
    return l.isEmpty ? null : Categoria.fromMap(l.first);
  }

  Future<int> inserir(Categoria c) async {
    final db = await _helper.database;
    try {
      return await db.insert('categorias', c.toMap()..remove('id'));
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw CategoriaDuplicadaException();
      rethrow;
    }
  }

  Future<void> atualizar(Categoria c) async {
    final db = await _helper.database;
    if (c.tipo != (await buscar(c.id!))?.tipo && await emUso(c.id!)) {
      throw CategoriaEmUsoException(
        'Não dá para trocar o tipo de uma categoria que já tem lançamentos.',
      );
    }
    try {
      await db.update(
        'categorias',
        c.toMap(),
        where: 'id = ?',
        whereArgs: [c.id],
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw CategoriaDuplicadaException();
      rethrow;
    }
  }

  Future<bool> emUso(int id) async {
    final db = await _helper.database;
    final r = await db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM lancamentos WHERE categoria_id = ?) AS l, '
      '(SELECT COUNT(*) FROM orcamentos WHERE categoria_id = ?) AS o',
      [id, id],
    );
    return (r.first['l'] as int) > 0 || (r.first['o'] as int) > 0;
  }

  /// Bloqueia a exclusão se a categoria estiver em uso, com mensagem clara.
  Future<void> excluir(int id) async {
    final db = await _helper.database;
    final r = await db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM lancamentos WHERE categoria_id = ?) AS l, '
      '(SELECT COUNT(*) FROM orcamentos WHERE categoria_id = ?) AS o',
      [id, id],
    );
    final lancamentos = r.first['l'] as int;
    final orcamentos = r.first['o'] as int;
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
