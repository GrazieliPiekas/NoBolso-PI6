import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// Perfil local (sem login): nome do usuário e flag de primeira abertura.
class ConfiguracaoDao {
  final DatabaseHelper _helper;
  ConfiguracaoDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  static const chaveNome = 'nome_usuario';
  static const chaveBoasVindas = 'boas_vindas_vista';
  static const chaveTutorial = 'tutorial_visto';

  /// Lê um valor da tabela chave/valor `configuracoes` (null se não existir).
  Future<String?> ler(String chave) async {
    final db = await _helper.database;
    final linhas = await db.query(
      'configuracoes',
      where: 'chave = ?',
      whereArgs: [chave],
    );
    return linhas.isEmpty ? null : linhas.first['valor'] as String?;
  }

  /// Grava ou substitui o valor da chave (INSERT OR REPLACE).
  Future<void> gravar(String chave, String? valor) async {
    final db = await _helper.database;
    await db.insert('configuracoes', {
      'chave': chave,
      'valor': valor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> nomeUsuario() async {
    final nome = (await ler(chaveNome))?.trim();
    return (nome == null || nome.isEmpty) ? null : nome;
  }

  Future<void> salvarNome(String? nome) => gravar(chaveNome, nome?.trim());

  Future<bool> boasVindasVista() async => (await ler(chaveBoasVindas)) == '1';

  Future<void> marcarBoasVindasVista() => gravar(chaveBoasVindas, '1');

  /// true depois que a pessoa terminou (ou pulou) o tutorial do primeiro acesso.
  Future<bool> tutorialVisto() async => (await ler(chaveTutorial)) == '1';

  Future<void> marcarTutorialVisto() => gravar(chaveTutorial, '1');
}
