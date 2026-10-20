import 'package:flutter/foundation.dart';

import '../database/configuracao_dao.dart';

/// Elementos da tela que o tutorial destaca. A View liga cada um a um widget.
enum AlvoTutorial { botaoNovo, saldo, abaOrcamento, abaRelatorios, menu }

/// Um passo do tutorial: o que destacar e a frase do balão.
class PassoTutorial {
  final AlvoTutorial alvo;
  final String texto;
  const PassoTutorial(this.alvo, this.texto);
}

/// Tutorial do primeiro acesso: só o essencial, uma frase curta por passo.
class TutorialViewModel extends ChangeNotifier {
  static const passos = [
    PassoTutorial(
      AlvoTutorial.botaoNovo,
      'Toque aqui para registrar um gasto ou um dinheiro que entrou.',
    ),
    PassoTutorial(AlvoTutorial.saldo, 'Aqui você vê quanto sobrou no mês.'),
    PassoTutorial(
      AlvoTutorial.abaOrcamento,
      'Defina um limite e o app avisa quando estiver chegando nele.',
    ),
    PassoTutorial(
      AlvoTutorial.abaRelatorios,
      'Exporte seus gastos em PDF ou planilha.',
    ),
    PassoTutorial(
      AlvoTutorial.menu,
      'Seus lançamentos e categorias ficam aqui.',
    ),
  ];

  int indice = 0;

  PassoTutorial get passoAtual => passos[indice];
  bool get ultimoPasso => indice == passos.length - 1;
  String get contador => '${indice + 1} de ${passos.length}';

  /// Mostra o tutorial só se a pessoa ainda não viu (nem pulou).
  static Future<bool> precisaMostrar() async =>
      !(await ConfiguracaoDao().tutorialVisto());

  /// Vai para o próximo passo. Devolve true quando já estava no último,
  /// ou seja, quando é hora de fechar o tutorial.
  bool avancar() {
    if (ultimoPasso) return true;
    indice++;
    notifyListeners();
    return false;
  }

  /// Grava que o tutorial foi visto, para não aparecer de novo sozinho.
  Future<void> concluir() => ConfiguracaoDao().marcarTutorialVisto();
}
