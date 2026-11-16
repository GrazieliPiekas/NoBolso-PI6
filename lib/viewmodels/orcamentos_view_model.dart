import 'package:flutter/foundation.dart';

import '../services/orcamento_service.dart';
import '../utils/eventos.dart';
import 'carregamento_seguro.dart';

/// Orçamentos do mês: medidor, avisos e limites por categoria (RF03/RF04).
class OrcamentosViewModel extends ChangeNotifier with CarregamentoSeguro {
  final _servico = OrcamentoService();

  ResumoOrcamentos? resumo;
  int versao = 0;

  /// Carrega o resumo e escuta os eventos (um lançamento novo muda o medidor).
  OrcamentosViewModel() {
    Eventos.dadosAlterados.addListener(carregar);
    carregar();
  }

  /// Recalcula o resumo do mês atual.
  Future<void> carregar() => carregarComSeguranca(() async {
    resumo = await _servico.resumo(DateTime.now());
    versao++;
  });

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(carregar);
    super.dispose();
  }
}
