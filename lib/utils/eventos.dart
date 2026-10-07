import 'package:flutter/foundation.dart';

/// Avisa as telas abertas que os dados mudaram, para recarregarem com setState.
/// (O plano evita Provider/Bloc; um contador global basta.)
class Eventos {
  Eventos._();

  static final dadosAlterados = ValueNotifier<int>(0);
  static final perfilAlterado = ValueNotifier<int>(0);

  static void notificarDados() => dadosAlterados.value++;
  static void notificarPerfil() => perfilAlterado.value++;
}
