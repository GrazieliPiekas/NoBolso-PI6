import 'package:sqflite/sqflite.dart';

import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../utils/formatadores.dart';
import 'database_helper.dart';

/// Total de despesas de uma categoria num período.
class TotalCategoria {
  final int categoriaId;
  final String nome;
  final int cor;
  final int totalCentavos;
  const TotalCategoria(
    this.categoriaId,
    this.nome,
    this.cor,
    this.totalCentavos,
  );
}

/// Receitas, despesas e quantidade de um período (valores em centavos).
class Totais {
  final int receitas;
  final int despesas;
  final int quantidade;
  const Totais(this.receitas, this.despesas, this.quantidade);
  int get saldo => receitas - despesas;
}

/// DAO dos lançamentos: CRUD e as consultas de soma usadas nos gráficos.
class LancamentoDao {
  final DatabaseHelper _helper;
  LancamentoDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  static const _selectComCategoria = '''
    SELECT l.*, c.nome AS categoria_nome, c.cor AS categoria_cor
    FROM lancamentos l JOIN categorias c ON c.id = l.categoria_id''';

  /// Insere um lançamento novo e devolve o id criado pelo banco.
  Future<int> inserir(Lancamento lancamento) async {
    final db = await _helper.database;
    return db.insert('lancamentos', lancamento.toMap()..remove('id'));
  }

  /// Inserção em lote numa única transação (gerador de dados de teste).
  Future<void> inserirVarios(List<Lancamento> itens) async {
    final db = await _helper.database;
    await db.transaction((transacao) async {
      final lote = transacao.batch();
      for (final lancamento in itens) {
        lote.insert('lancamentos', lancamento.toMap()..remove('id'));
      }
      await lote.commit(noResult: true);
    });
  }

  Future<void> atualizar(Lancamento lancamento) async {
    final db = await _helper.database;
    await db.update(
      'lancamentos',
      lancamento.toMap(),
      where: 'id = ?',
      whereArgs: [lancamento.id],
    );
  }

  Future<void> excluir(int id) async {
    final db = await _helper.database;
    await db.delete('lancamentos', where: 'id = ?', whereArgs: [id]);
  }

  /// Apaga todos os lançamentos (só usado pelo botão de teste do modo debug).
  Future<void> excluirTodos() async {
    final db = await _helper.database;
    await db.delete('lancamentos');
  }

  Future<List<Lancamento>> listar({
    Periodo? periodo,
    Tipo? tipo,
    int? categoriaId,
    int? limite,
  }) async {
    final db = await _helper.database;
    final (where, args) = _filtros(periodo, tipo, categoriaId);
    final linhas = await db.rawQuery(
      '$_selectComCategoria $where ORDER BY l.data DESC, l.id DESC'
      '${limite != null ? ' LIMIT $limite' : ''}',
      args,
    );
    return linhas.map(Lancamento.fromMap).toList();
  }

  Future<Totais> totais({
    Periodo? periodo,
    Tipo? tipo,
    int? categoriaId,
  }) async {
    final db = await _helper.database;
    final (where, args) = _filtros(periodo, tipo, categoriaId);
    final resultado = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN l.tipo = 'receita' THEN l.valor_centavos END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN l.tipo = 'despesa' THEN l.valor_centavos END), 0) AS despesas,
        COUNT(*) AS qtd
      FROM lancamentos l $where''', args);
    return Totais(
      resultado.first['receitas'] as int,
      resultado.first['despesas'] as int,
      resultado.first['qtd'] as int,
    );
  }

  /// Despesas agrupadas por categoria, do maior para o menor.
  Future<List<TotalCategoria>> despesasPorCategoria(Periodo periodo) async {
    final db = await _helper.database;
    final resultado = await db.rawQuery(
      '''
      SELECT c.id, c.nome, c.cor, SUM(l.valor_centavos) AS total
      FROM lancamentos l JOIN categorias c ON c.id = l.categoria_id
      WHERE l.tipo = 'despesa' AND l.data BETWEEN ? AND ?
      GROUP BY c.id ORDER BY total DESC''',
      [periodo.deDb, periodo.ateDb],
    );
    return resultado
        .map(
          (linha) => TotalCategoria(
            linha['id'] as int,
            linha['nome'] as String,
            linha['cor'] as int,
            linha['total'] as int,
          ),
        )
        .toList();
  }

  /// Total de despesas de uma categoria (ou de todas, se null) no período.
  Future<int> despesasDaCategoria(int? categoriaId, Periodo periodo) async {
    final db = await _helper.database;
    final resultado = await db.rawQuery(
      'SELECT COALESCE(SUM(valor_centavos), 0) AS t FROM lancamentos '
      "WHERE tipo = 'despesa' AND data BETWEEN ? AND ?"
      '${categoriaId != null ? ' AND categoria_id = ?' : ''}',
      [periodo.deDb, periodo.ateDb, ?categoriaId],
    );
    return resultado.first['t'] as int;
  }

  /// Receitas e despesas de cada dia do período: 'YYYY-MM-DD' → (receitas, despesas).
  Future<Map<String, (int, int)>> totaisPorDia(Periodo periodo) async {
    final db = await _helper.database;
    final resultado = await db.rawQuery(
      '''
      SELECT data,
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor_centavos END), 0) AS rec,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor_centavos END), 0) AS desp
      FROM lancamentos WHERE data BETWEEN ? AND ?
      GROUP BY data''',
      [periodo.deDb, periodo.ateDb],
    );
    return {
      for (final linha in resultado)
        linha['data'] as String: (linha['rec'] as int, linha['desp'] as int),
    };
  }

  /// Receitas e despesas de cada mês do período: 'YYYY-MM' → (receitas, despesas).
  Future<Map<String, (int, int)>> totaisPorMes(Periodo periodo) async {
    final db = await _helper.database;
    final resultado = await db.rawQuery(
      '''
      SELECT substr(data, 1, 7) AS mes,
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor_centavos END), 0) AS rec,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor_centavos END), 0) AS desp
      FROM lancamentos WHERE data BETWEEN ? AND ?
      GROUP BY mes''',
      [periodo.deDb, periodo.ateDb],
    );
    return {
      for (final linha in resultado)
        linha['mes'] as String: (linha['rec'] as int, linha['desp'] as int),
    };
  }

  /// Quantos lançamentos existem no banco (usado no teste de desempenho).
  Future<int> contar() async {
    final db = await _helper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM lancamentos'),
        ) ??
        0;
  }

  (String, List<Object?>) _filtros(
    Periodo? periodo,
    Tipo? tipo,
    int? categoriaId,
  ) {
    final partes = <String>[];
    final args = <Object?>[];
    if (periodo != null) {
      partes.add('l.data BETWEEN ? AND ?');
      args.addAll([periodo.deDb, periodo.ateDb]);
    }
    if (tipo != null) {
      partes.add('l.tipo = ?');
      args.add(tipo.name);
    }
    if (categoriaId != null) {
      partes.add('l.categoria_id = ?');
      args.add(categoriaId);
    }
    return (partes.isEmpty ? '' : 'WHERE ${partes.join(' AND ')}', args);
  }
}
