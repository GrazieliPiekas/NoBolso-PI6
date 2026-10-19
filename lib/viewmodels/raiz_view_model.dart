import 'package:flutter/foundation.dart';

import '../database/configuracao_dao.dart';

/// Decide entre abertura (carregando), boas-vindas e o app.
class RaizViewModel extends ChangeNotifier {
  /// null enquanto o banco abre.
  bool? boasVindasVista;

  RaizViewModel() {
    _carregar();
  }

  Future<void> _carregar() async {
    final resultados = await Future.wait([
      ConfiguracaoDao().boasVindasVista(),
      // Deixa a marca visível por um instante, mesmo com o banco já pronto.
      Future.delayed(const Duration(milliseconds: 700), () => true),
    ]);
    boasVindasVista = resultados.first;
    notifyListeners();
  }

  /// Chamado quando a pessoa termina as boas-vindas: vai para o app.
  void boasVindasConcluidas() {
    boasVindasVista = true;
    notifyListeners();
  }
}
