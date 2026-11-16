import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';
import '../utils/eventos.dart';
import 'carregamento_seguro.dart';

/// Tela de backup: gera a cópia dos dados e restaura a partir de um arquivo.
class BackupViewModel extends ChangeNotifier with CarregamentoSeguro {
  final BackupService _servico;
  BackupViewModel([BackupService? servico])
    : _servico = servico ?? BackupService();

  bool ocupado = false;

  /// Gera o backup e abre o compartilhar do sistema para a pessoa escolher
  /// onde guardar. Erros sobem para a View mostrar.
  Future<void> fazerBackup() => _ocupado(() async {
    final arquivo = await _servico.gerarBackup();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(arquivo.path)],
        subject: 'Backup NoBolso',
        text: 'Backup dos meus dados do NoBolso. Guarde este arquivo.',
      ),
    );
  });

  /// Abre o seletor de arquivos, copia o escolhido para uma pasta temporária
  /// e confere se é um backup válido. Devolve null se a pessoa cancelou.
  /// Lança [BackupInvalidoException] se o arquivo não servir.
  Future<File?> escolherArquivo() async {
    File? escolhido;
    await _ocupado(() async {
      final arquivo = await FilePicker.pickFile(
        dialogTitle: 'Escolha o backup',
      );
      if (arquivo == null) return;
      // No Android o arquivo pode vir como "content://", sem caminho direto.
      // Salvar uma cópia temporária resolve para qualquer origem.
      final pasta = await getTemporaryDirectory();
      final copia = p.join(pasta.path, 'nobolso_restaurar.db');
      await arquivo.xFile.saveTo(copia);
      final file = File(copia);
      await _servico.validar(file);
      escolhido = file;
    });
    return escolhido;
  }

  /// Troca os dados atuais pelos do backup e avisa todas as telas.
  Future<void> restaurar(File arquivo) => _ocupado(() async {
    await _servico.restaurar(arquivo);
    Eventos.notificarDados();
    Eventos.notificarPerfil();
  });

  Future<void> _ocupado(Future<void> Function() acao) async {
    ocupado = true;
    avisar();
    try {
      await acao();
    } finally {
      ocupado = false;
      avisar();
    }
  }
}
