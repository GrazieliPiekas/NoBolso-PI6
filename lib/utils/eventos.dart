import 'package:flutter/foundation.dart';

/// Avisa os ViewModels que os dados mudaram, para eles recarregarem.
/// Ex.: salvou um lançamento no formulário → Início, Análise e Orçamentos
/// atualizam sozinhos. É só um contador: cada aviso soma 1 e quem está
/// escutando é chamado. Não precisou de Provider nem Bloc.
class Eventos {
  Eventos._();

  static final dadosAlterados = ValueNotifier<int>(0);
  static final perfilAlterado = ValueNotifier<int>(0);

  /// Chamado depois de salvar/excluir algo: as abas abertas recarregam.
  static void notificarDados() => dadosAlterados.value++;

  /// Chamado quando o nome do usuário muda (atualiza o "Olá, ...").
  static void notificarPerfil() => perfilAlterado.value++;
}
