import 'package:sqflite/sqflite.dart';

import '../models/orcamento.dart';
import 'database_helper.dart';

class OrcamentoDuplicadoException implements Exception {
  @override
  String toString() => 'Já existe um orçamento para essa categoria.';
}

class OrcamentoDao {
  final DatabaseHelper _helper;
  OrcamentoDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  /// Geral primeiro, depois por categoria em ordem alfabética.
  Future<List<Orcamento>> listar() async {
    final db = await _helper.database;
    final r = await db.rawQuery('''
      SELECT o.*, c.nome AS categoria_nome, c.cor AS categoria_cor
      FROM orcamentos o LEFT JOIN categorias c ON c.id = o.categoria_id
      ORDER BY o.categoria_id IS NOT NULL, c.nome COLLATE NOCASE''');
    return r.map(Orcamento.fromMap).toList();
  }

  Future<int> inserir(Orcamento o) async {
    final db = await _helper.database;
    try {
      return await db.insert('orcamentos', o.toMap()..remove('id'));
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw OrcamentoDuplicadoException();
      rethrow;
    }
  }

  Future<void> atualizar(Orcamento o) async {
    final db = await _helper.database;
    try {
      await db.update(
        'orcamentos',
        o.toMap(),
        where: 'id = ?',
        whereArgs: [o.id],
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw OrcamentoDuplicadoException();
      rethrow;
    }
    // Novo limite: os níveis de alerta deste orçamento voltam a valer.
    await db.delete(
      'alertas_enviados',
      where: 'orcamento_id = ?',
      whereArgs: [o.id],
    );
  }

  Future<void> excluir(int id) async {
    final db = await _helper.database;
    await db.delete('orcamentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<int>> niveisEnviados(int orcamentoId, String referencia) async {
    final db = await _helper.database;
    final r = await db.query(
      'alertas_enviados',
      columns: ['nivel'],
      where: 'orcamento_id = ? AND referencia = ?',
      whereArgs: [orcamentoId, referencia],
    );
    return r.map((m) => m['nivel'] as int).toSet();
  }

  Future<void> registrarAlerta(
    int orcamentoId,
    String referencia,
    int nivel,
  ) async {
    final db = await _helper.database;
    await db.insert('alertas_enviados', {
      'orcamento_id': orcamentoId,
      'referencia': referencia,
      'nivel': nivel,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
