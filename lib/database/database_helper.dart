import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tipo.dart';

/// Abre o banco SQLite local, cria as tabelas e insere as categorias padrão.
/// Nada sai do aparelho: não há sincronização nem rede.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _nomeArquivo = 'nobolso.db';
  static const _versao = 1;

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
    );
  }

  Future<void> fechar() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _criar(Database db, int versao) async {
    final b = db.batch();
    b.execute('''
      CREATE TABLE categorias (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        nome  TEXT NOT NULL,
        tipo  TEXT NOT NULL CHECK (tipo IN ('receita','despesa')),
        cor   INTEGER NOT NULL,
        UNIQUE (nome, tipo)
      )''');
    b.execute('''
      CREATE TABLE lancamentos (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao       TEXT NOT NULL,
        valor_centavos  INTEGER NOT NULL CHECK (valor_centavos > 0),
        tipo            TEXT NOT NULL CHECK (tipo IN ('receita','despesa')),
        categoria_id    INTEGER NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
        data            TEXT NOT NULL
      )''');
    b.execute('CREATE INDEX idx_lancamentos_data ON lancamentos(data)');
    b.execute(
      'CREATE INDEX idx_lancamentos_categoria ON lancamentos(categoria_id)',
    );
    b.execute('''
      CREATE TABLE orcamentos (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria_id     INTEGER UNIQUE REFERENCES categorias(id) ON DELETE RESTRICT,
        limite_centavos  INTEGER NOT NULL CHECK (limite_centavos > 0)
      )''');
    // UNIQUE não impede vários NULL no SQLite: este índice garante um único orçamento geral.
    b.execute(
      'CREATE UNIQUE INDEX idx_orcamento_geral ON orcamentos((categoria_id IS NULL)) '
      'WHERE categoria_id IS NULL',
    );
    b.execute('''
      CREATE TABLE alertas_enviados (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        orcamento_id  INTEGER NOT NULL REFERENCES orcamentos(id) ON DELETE CASCADE,
        referencia    TEXT NOT NULL,
        nivel         INTEGER NOT NULL CHECK (nivel IN (50, 80, 100)),
        UNIQUE (orcamento_id, referencia, nivel)
      )''');
    b.execute('''
      CREATE TABLE configuracoes (
        chave  TEXT PRIMARY KEY,
        valor  TEXT
      )''');

    for (final c in categoriasPadrao) {
      b.insert('categorias', {
        'nome': c.$1,
        'tipo': c.$2.name,
        'cor': c.$3,
      });
    }
    await b.commit(noResult: true);
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
