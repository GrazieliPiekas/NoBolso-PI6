import 'package:flutter/foundation.dart';

import '../database/configuracao_dao.dart';

/// Primeira abertura: guarda o nome (opcional) e marca as boas-vindas como vistas.
class BoasVindasViewModel extends ChangeNotifier {
  final _dao = ConfiguracaoDao();
  bool salvando = false;

  /// Salva o nome (se a pessoa digitou) e marca que as boas-vindas já foram vistas.
  Future<void> concluir(String? nome) async {
    salvando = true;
    notifyListeners();
    if (nome != null && nome.trim().isNotEmpty) await _dao.salvarNome(nome);
    await _dao.marcarBoasVindasVista();
  }
}
