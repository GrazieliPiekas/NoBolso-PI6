import 'package:sqflite/sqflite.dart';

import '../models/orcamento.dart';
import 'database_helper.dart';

/// Erro quando já existe orçamento para a mesma categoria (ou dois gerais).
class OrcamentoDuplicadoException implements Exception {
  @override
  String toString() => 'Já existe um orçamento para essa categoria.';
}

/// DAO dos orçamentos e dos alertas que já foram enviados.
class OrcamentoDao {
  final DatabaseHelper _helper;
  OrcamentoDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  /// Geral primeiro, depois por categoria em ordem alfabética.
  Future<List<Orcamento>> listar() async {
    final db = await _helper.database;
    final resultado = await db.rawQuery('''
      SELECT o.*, c.nome AS categoria_nome, c.cor AS categoria_cor
      FROM orcamentos o LEFT JOIN categorias c ON c.id = o.categoria_id
      ORDER BY o.categoria_id IS NOT NULL, c.nome COLLATE NOCASE''');
    return resultado.map(Orcamento.fromMap).toList();
  }

  Future<int> inserir(Orcamento orcamento) async {
    final db = await _helper.database;
    try {
      return await db.insert('orcamentos', orcamento.toMap()..remove('id'));
    } on DatabaseException catch (erro) {
      if (erro.isUniqueConstraintError()) throw OrcamentoDuplicadoException();
      rethrow;
    }
  }

  Future<void> atualizar(Orcamento orcamento) async {
    final db = await _helper.database;
    try {
      await db.update(
        'orcamentos',
        orcamento.toMap(),
        where: 'id = ?',
        whereArgs: [orcamento.id],
      );
    } on DatabaseException catch (erro) {
      if (erro.isUniqueConstraintError()) throw OrcamentoDuplicadoException();
      rethrow;
    }
    // Novo limite: os níveis de alerta deste orçamento voltam a valer.
    await db.delete(
      'alertas_enviados',
      where: 'orcamento_id = ?',
      whereArgs: [orcamento.id],
    );
  }

  Future<void> excluir(int id) async {
    final db = await _helper.database;
    await db.delete('orcamentos', where: 'id = ?', whereArgs: [id]);
  }

  /// Quais níveis (50, 80, 100) já foram avisados para esse orçamento no mês.
  /// Serve pra não mandar a mesma notificação duas vezes.
  Future<Set<int>> niveisEnviados(int orcamentoId, String referencia) async {
    final db = await _helper.database;
    final resultado = await db.query(
      'alertas_enviados',
      columns: ['nivel'],
      where: 'orcamento_id = ? AND referencia = ?',
      whereArgs: [orcamentoId, referencia],
    );
    return resultado.map((linha) => linha['nivel'] as int).toSet();
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
