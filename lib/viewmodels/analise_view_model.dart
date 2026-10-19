import 'package:flutter/foundation.dart';

import '../services/dados_graficos_service.dart';
import '../utils/eventos.dart';

/// Estado da Análise: filtro Mês/Trimestre/Ano e dados da linha e do mapa de calor.
class AnaliseViewModel extends ChangeNotifier {
  final _servico = DadosGraficosService();

  FiltroAnalise filtro = FiltroAnalise.mes;
  DadosAnalise? dados;
  int versao = 0;

  /// Escuta [Eventos.dadosAlterados]: se um lançamento for salvo em outra tela,
  /// os gráficos daqui se atualizam sozinhos.
  AnaliseViewModel() {
    Eventos.dadosAlterados.addListener(carregar);
    carregar();
  }

  /// Busca os dados do filtro atual e avisa a View (notifyListeners) para redesenhar.
  Future<void> carregar() async {
    dados = await _servico.analise(filtro);
    versao++;
    notifyListeners();
  }

  /// Troca Mês/Trimestre/Ano e recarrega.
  void mudarFiltro(FiltroAnalise novoFiltro) {
    filtro = novoFiltro;
    notifyListeners();
    carregar();
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(carregar);
    super.dispose();
  }
}
