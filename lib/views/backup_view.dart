import 'dart:io';

import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/backup_view_model.dart';
import '../widgets/componentes.dart';

/// Backup e restauração dos dados. Como tudo fica só no celular, esta é a
/// forma de não perder nada ao trocar de aparelho ou reinstalar o app.
class BackupView extends StatefulWidget {
  const BackupView({super.key});
  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = BackupViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _fazerBackup() async {
    try {
      await _viewModel.fazerBackup();
    } catch (erro) {
      _avisar('Não foi possível gerar o backup: $erro');
    }
  }

  Future<void> _restaurar() async {
    File? arquivo;
    try {
      arquivo = await _viewModel.escolherArquivo();
    } on BackupInvalidoException catch (erro) {
      _avisar(erro.mensagem);
      return;
    } catch (erro) {
      _avisar('Não foi possível abrir o arquivo: $erro');
      return;
    }
    if (arquivo == null || !mounted) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Restaurar este backup?'),
        content: const Text(
          'Todos os dados atuais (lançamentos, categorias, orçamentos e perfil) '
          'serão trocados pelos do backup. Isso não pode ser desfeito.\n\n'
          'Se quiser guardar os dados de agora, faça um backup antes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            style: TextButton.styleFrom(foregroundColor: Cores.despesa),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await _viewModel.restaurar(arquivo);
      _avisar('Backup restaurado.');
    } catch (erro) {
      _avisar('Não foi possível restaurar: $erro');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup dos dados')),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Aviso(
            alerta: false,
            titulo: 'Seus dados ficam só neste celular',
            mensagem:
                'Se trocar de aparelho ou desinstalar o app, eles se perdem. '
                'Faça um backup de vez em quando e guarde o arquivo onde '
                'preferir (Drive, e-mail, WhatsApp...).',
          ),
          CartaoSecao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _viewModel.ocupado ? null : _fazerBackup,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Fazer backup agora'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gera um arquivo .db com tudo o que está no app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.textoSuave, fontSize: 13),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _viewModel.ocupado ? null : _restaurar,
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('Restaurar de um arquivo'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha um backup feito antes pelo NoBolso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.textoSuave, fontSize: 13),
                ),
                if (_viewModel.ocupado) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(color: Cores.verde),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
