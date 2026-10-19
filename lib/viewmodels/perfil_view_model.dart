import 'package:flutter/foundation.dart';

import '../database/configuracao_dao.dart';
import '../database/lancamento_dao.dart';
import '../services/gerador_dados_service.dart';
import '../utils/eventos.dart';

/// Perfil local (nome) e ferramentas de teste do modo debug.
class PerfilViewModel extends ChangeNotifier {
  final _config = ConfiguracaoDao();

  bool ocupado = false;
  String? status;

  Future<String?> nomeAtual() => _config.nomeUsuario();

  Future<void> salvarNome(String nome) async {
    await _config.salvarNome(nome);
    Eventos.notificarPerfil();
  }

  /// Gera lançamentos fictícios para testar o app com bastante dado
  /// e mede quanto tempo o banco levou.
  Future<void> gerar(int qtd) async {
    ocupado = true;
    status = 'Gerando $qtd lançamentos...';
    notifyListeners();
    final tempo = await GeradorDadosService().gerar(qtd);
    final total = await LancamentoDao().contar();
    Eventos.notificarDados();
    ocupado = false;
    status =
        '$qtd inseridos em ${tempo.inMilliseconds} ms. Total no banco: $total.';
    notifyListeners();
  }

  /// Apaga todos os lançamentos (botão de teste, só aparece em debug).
  Future<void> apagarTudo() async {
    ocupado = true;
    notifyListeners();
    await LancamentoDao().excluirTodos();
    Eventos.notificarDados();
    ocupado = false;
    status = 'Todos os lançamentos foram apagados.';
    notifyListeners();
  }
}
