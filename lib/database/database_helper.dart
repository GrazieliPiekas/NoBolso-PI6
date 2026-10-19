import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tipo.dart';

/// Abre o banco SQLite local, cria as tabelas e insere as categorias padrão.
/// Nada sai do aparelho: não há sincronização nem rede.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _nomeArquivo = 'nobolso.db';

  /// v2: coluna booleana `fixo` em lançamentos.
  static const _versao = 2;

  /// Nos testes recebe `inMemoryDatabasePath`.
  String? caminhoPersonalizado;

  Database? _db;

  Future<Database> get database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final caminho =
        caminhoPersonalizado ?? join(await getDatabasesPath(), _nomeArquivo);
    return openDatabase(
      caminho,
      version: _versao,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _criar,
      onUpgrade: _atualizar,
    );
  }

  /// Migração de quem já tinha o banco v1: nada é perdido.
  static Future<void> _atualizar(Database db, int de, int para) async {
    if (de < 2) {
      await db.execute(
        'ALTER TABLE lancamentos ADD COLUMN '
        'fixo INTEGER NOT NULL DEFAULT 0 CHECK (fixo IN (0, 1))',
      );
    }
  }

  /// Fecha o banco. Usado nos testes para começar cada um com um banco limpo.
  Future<void> fechar() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _criar(Database db, int versao) async {
    final lote = db.batch();
    lote.execute('''
      CREATE TABLE categorias (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        nome  TEXT NOT NULL,
        tipo  TEXT NOT NULL CHECK (tipo IN ('receita','despesa')),
        cor   INTEGER NOT NULL,
        UNIQUE (nome, tipo)
      )''');
    lote.execute('''
      CREATE TABLE lancamentos (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao       TEXT NOT NULL,
        valor_centavos  INTEGER NOT NULL CHECK (valor_centavos > 0),
        tipo            TEXT NOT NULL CHECK (tipo IN ('receita','despesa')),
        categoria_id    INTEGER NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
        data            TEXT NOT NULL,
        fixo            INTEGER NOT NULL DEFAULT 0 CHECK (fixo IN (0, 1))
      )''');
    lote.execute('CREATE INDEX idx_lancamentos_data ON lancamentos(data)');
    lote.execute(
      'CREATE INDEX idx_lancamentos_categoria ON lancamentos(categoria_id)',
    );
    lote.execute('''
      CREATE TABLE orcamentos (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria_id     INTEGER UNIQUE REFERENCES categorias(id) ON DELETE RESTRICT,
        limite_centavos  INTEGER NOT NULL CHECK (limite_centavos > 0)
      )''');
    // UNIQUE não impede vários NULL no SQLite: este índice garante um único orçamento geral.
    lote.execute(
      'CREATE UNIQUE INDEX idx_orcamento_geral ON orcamentos((categoria_id IS NULL)) '
      'WHERE categoria_id IS NULL',
    );
    lote.execute('''
      CREATE TABLE alertas_enviados (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        orcamento_id  INTEGER NOT NULL REFERENCES orcamentos(id) ON DELETE CASCADE,
        referencia    TEXT NOT NULL,
        nivel         INTEGER NOT NULL CHECK (nivel IN (50, 80, 100)),
        UNIQUE (orcamento_id, referencia, nivel)
      )''');
    lote.execute('''
      CREATE TABLE configuracoes (
        chave  TEXT PRIMARY KEY,
        valor  TEXT
      )''');

    for (final categoria in categoriasPadrao) {
      lote.insert('categorias', {
        'nome': categoria.$1,
        'tipo': categoria.$2.name,
        'cor': categoria.$3,
      });
    }
    await lote.commit(noResult: true);
  }

  /// Decisão 12 do plano.
  static const categoriasPadrao = <(String, Tipo, int)>[
    ('Alimentação', Tipo.despesa, 0xFF7FA67B),
    ('Transporte', Tipo.despesa, 0xFF5A7A8A),
    ('Moradia', Tipo.despesa, 0xFF3E6A46),
    ('Lazer', Tipo.despesa, 0xFFC98A3A),
    ('Saúde', Tipo.despesa, 0xFF8A7088),
    ('Educação', Tipo.despesa, 0xFFA0785A),
    ('Outros', Tipo.despesa, 0xFF8A8A7A),
    ('Salário', Tipo.receita, 0xFF3E6A46),
    ('Outros', Tipo.receita, 0xFF7FA67B),
  ];
}
