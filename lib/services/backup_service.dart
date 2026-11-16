import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../utils/formatadores.dart';

/// Lançada quando o arquivo escolhido para restaurar não é um backup do NoBolso.
class BackupInvalidoException implements Exception {
  final String mensagem;
  BackupInvalidoException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Backup e restauração dos dados.
///
/// Como o app é 100% offline, os dados só existem no celular: se a pessoa
/// trocar de aparelho ou desinstalar o app, perde tudo. O backup é uma cópia
/// do próprio arquivo SQLite (nobolso.db), que ela guarda onde quiser
/// (Drive, WhatsApp, e-mail...) pelo compartilhamento do sistema.
/// Nada é enviado pelo app: quem escolhe o destino é o usuário.
class BackupService {
  final DatabaseHelper _helper;
  BackupService([DatabaseHelper? helper])
    : _helper = helper ?? DatabaseHelper.instance;

  /// Tabelas que um backup válido precisa ter.
  static const tabelasObrigatorias = {
    'categorias',
    'lancamentos',
    'orcamentos',
    'alertas_enviados',
    'configuracoes',
  };

  /// Gera uma cópia do banco numa pasta temporária e devolve o arquivo.
  /// [pasta] só é passado nos testes.
  Future<File> gerarBackup({Directory? pasta, DateTime? hoje}) async {
    final destinoPasta = pasta ?? await getTemporaryDirectory();
    final data = Formatadores.dataParaDb(hoje ?? DateTime.now());
    final destino = File(p.join(destinoPasta.path, 'nobolso_backup_$data.db'));
    final origem = File(await _helper.caminhoArquivo());

    // Garante que o arquivo existe (o banco pode ainda não ter sido aberto).
    await _helper.database;
    // Fecha o banco antes de copiar: garante que tudo foi gravado no arquivo.
    // Ele reabre sozinho no próximo acesso.
    await _helper.fechar();
    if (await destino.exists()) await destino.delete();
    return origem.copy(destino.path);
  }

  /// Troca os dados atuais pelos do arquivo de backup.
  /// Antes confere se o arquivo é mesmo um banco do NoBolso; se não for,
  /// lança [BackupInvalidoException] e os dados atuais ficam intactos.
  Future<void> restaurar(File arquivo) async {
    await validar(arquivo);
    final caminho = await _helper.caminhoArquivo();
    // Copia primeiro para um arquivo ao lado e só depois troca: se a cópia
    // falhar no meio, o banco atual continua inteiro.
    final temporario = await arquivo.copy('$caminho.restaurando');
    await _helper.fechar();
    // Apaga os arquivos extras que o SQLite cria ao lado do banco antigo.
    for (final sufixo in ['-wal', '-shm', '-journal']) {
      final resto = File('$caminho$sufixo');
      if (await resto.exists()) await resto.delete();
    }
    await temporario.rename(caminho);
    // Abre já, para rodar a migração (ex.: backup da versão 1 ganha a coluna `fixo`).
    await _helper.database;
  }

  /// Abre o arquivo só para leitura e confere as tabelas e a versão.
  Future<void> validar(File arquivo) async {
    if (!await arquivo.exists()) {
      throw BackupInvalidoException('O arquivo não foi encontrado.');
    }
    Database? db;
    try {
      db = await openDatabase(arquivo.path, readOnly: true);
      final linhas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tabelas = linhas.map((linha) => linha['name'] as String).toSet();
      if (!tabelas.containsAll(tabelasObrigatorias)) {
        throw BackupInvalidoException(
          'Este arquivo não é um backup do NoBolso.',
        );
      }
      final versaoArquivo = await db.getVersion();
      if (versaoArquivo > DatabaseHelper.versao) {
        throw BackupInvalidoException(
          'Este backup foi feito numa versão mais nova do NoBolso. '
          'Atualize o app antes de restaurar.',
        );
      }
    } on BackupInvalidoException {
      rethrow;
    } catch (_) {
      // Arquivo que nem abre como SQLite (foto, PDF, arquivo corrompido...).
      throw BackupInvalidoException('Este arquivo não é um backup do NoBolso.');
    } finally {
      await db?.close();
    }
  }
}
