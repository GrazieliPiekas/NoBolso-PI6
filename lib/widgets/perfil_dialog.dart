import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/configuracao_dao.dart';
import '../database/lancamento_dao.dart';
import '../services/gerador_dados_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';

/// Perfil local: só o nome, guardado no SQLite. Em modo debug mostra o gerador
/// de lançamentos fictícios para testes de desempenho e com participantes.
class PerfilDialog extends StatefulWidget {
  const PerfilDialog({super.key});

  static Future<void> abrir(BuildContext context) =>
      showDialog(context: context, builder: (_) => const PerfilDialog());

  @override
  State<PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<PerfilDialog> {
  final _nome = TextEditingController();
  final _config = ConfiguracaoDao();
  bool _ocupado = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _config.nomeUsuario().then((n) => _nome.text = n ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await _config.salvarNome(_nome.text);
    Eventos.notificarPerfil();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _gerar(int qtd) async {
    setState(() {
      _ocupado = true;
      _status = 'Gerando $qtd lançamentos...';
    });
    final tempo = await GeradorDadosService().gerar(qtd);
    final total = await LancamentoDao().contar();
    Eventos.notificarDados();
    if (mounted) {
      setState(() {
        _ocupado = false;
        _status =
            '$qtd inseridos em ${tempo.inMilliseconds} ms. Total no banco: $total.';
      });
    }
  }

  Future<void> _apagarTudo() async {
    setState(() => _ocupado = true);
    await LancamentoDao().excluirTodos();
    Eventos.notificarDados();
    if (mounted) {
      setState(() {
        _ocupado = false;
        _status = 'Todos os lançamentos foram apagados.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Seu perfil'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nome,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Como podemos te chamar?'),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: Cores.verde),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Não existe conta nem login. Seus dados ficam só neste '
                  'aparelho e nada é enviado para a internet.',
                  style: TextStyle(color: Cores.textoSuave, fontSize: 13),
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const Divider(height: 32),
            const Text(
              'Ferramentas de teste (só em debug)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in const [100, 1000, 10000])
                  OutlinedButton(
                    onPressed: _ocupado ? null : () => _gerar(n),
                    child: Text('+$n'),
                  ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Cores.despesa,
                  ),
                  onPressed: _ocupado ? null : _apagarTudo,
                  child: const Text('Apagar lançamentos'),
                ),
              ],
            ),
            if (_ocupado) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(color: Cores.verde),
            ],
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(onPressed: _salvar, child: const Text('Salvar')),
    ],
  );
}
