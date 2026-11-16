import 'package:flutter/foundation.dart';

/// Carregamento à prova de erro para os ViewModels.
///
/// Sem isto, se o banco falhasse ao abrir uma tela, a exceção se perdia e a
/// tela ficava girando para sempre. Agora o erro vira uma mensagem em [erro]
/// e a View mostra o botão "Tentar de novo" (ver o widget `Carregando`).
///
/// Também evita chamar `notifyListeners()` depois que a tela foi fechada
/// (uma consulta lenta pode terminar depois do `dispose`).
mixin CarregamentoSeguro on ChangeNotifier {
  /// Mensagem para o usuário quando o último carregamento falhou; null se deu certo.
  String? erro;

  bool _descartado = false;

  /// Roda [acao] tratando qualquer exceção. Antes de começar limpa o erro
  /// anterior, para a tela voltar a mostrar o indicador de carregamento.
  Future<void> carregarComSeguranca(Future<void> Function() acao) async {
    if (erro != null) {
      erro = null;
      avisar();
    }
    try {
      await acao();
    } catch (excecao, pilha) {
      debugPrint('Erro ao carregar ($runtimeType): $excecao\n$pilha');
      erro = 'Não foi possível carregar os dados. Tente de novo.';
    }
    avisar();
  }

  /// `notifyListeners()` que não quebra se a tela já foi fechada.
  void avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
