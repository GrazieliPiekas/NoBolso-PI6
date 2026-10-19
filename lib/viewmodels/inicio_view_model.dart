import 'package:flutter/foundation.dart';

import '../database/configuracao_dao.dart';
import '../services/dados_graficos_service.dart';
import '../utils/eventos.dart';

/// Estado do Início: totais do mês, dados dos gráficos e nome do usuário.
class InicioViewModel extends ChangeNotifier {
  final _servico = DadosGraficosService();
  final _config = ConfiguracaoDao();

  DadosInicio? dados;
  String? nome;

  /// Muda a cada recarga para reanimar os gráficos.
  int versao = 0;

  /// Já começa carregando e escuta os eventos para recarregar quando algo mudar.
  InicioViewModel() {
    Eventos.dadosAlterados.addListener(carregar);
    Eventos.perfilAlterado.addListener(carregarNome);
    carregar();
    carregarNome();
  }

  /// Busca totais e dados dos gráficos do mês atual.
  Future<void> carregar() async {
    dados = await _servico.inicio(DateTime.now());
    versao++;
    notifyListeners();
  }

  /// Busca o nome salvo no perfil (para o "Olá, ...").
  Future<void> carregarNome() async {
    nome = await _config.nomeUsuario();
    notifyListeners();
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(carregar);
    Eventos.perfilAlterado.removeListener(carregarNome);
    super.dispose();
  }
}
