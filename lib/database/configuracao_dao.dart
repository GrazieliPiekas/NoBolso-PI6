import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// Perfil local (sem login): nome do usuário e flag de primeira abertura.
class ConfiguracaoDao {
  final DatabaseHelper _helper;
  ConfiguracaoDao([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  static const chaveNome = 'nome_usuario';
  static const chaveBoasVindas = 'boas_vindas_vista';

  Future<String?> ler(String chave) async {
    final db = await _helper.database;
    final r = await db.query(
      'configuracoes',
      where: 'chave = ?',
      whereArgs: [chave],
    );
    return r.isEmpty ? null : r.first['valor'] as String?;
  }

  Future<void> gravar(String chave, String? valor) async {
    final db = await _helper.database;
    await db.insert('configuracoes', {
      'chave': chave,
      'valor': valor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> nomeUsuario() async {
    final n = (await ler(chaveNome))?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  Future<void> salvarNome(String? nome) => gravar(chaveNome, nome?.trim());

  Future<bool> boasVindasVista() async => (await ler(chaveBoasVindas)) == '1';

  Future<void> marcarBoasVindasVista() => gravar(chaveBoasVindas, '1');
}
