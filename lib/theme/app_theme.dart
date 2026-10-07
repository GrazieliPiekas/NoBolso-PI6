import 'package:flutter/material.dart';

/// Paleta do protótipo: verde + neutros claros (bege).
class Cores {
  Cores._();

  static const verde = Color(0xFF3E6A46);
  static const verdeEscuro = Color(0xFF2B4632);
  static const verdeClaro = Color(0xFF7FA67B);
  static const verdeSuave = Color(0xFFDCE5D6);

  static const despesa = Color(0xFFB85C41);
  static const despesaClara = Color(0xFFDCA68D);
  static const alerta = Color(0xFFC98A3A);
  static const alertaFundo = Color(0xFFEDDBC6);

  static const fundo = Color(0xFFEFE5DA);
  static const cartao = Color(0xFFFAF5EF);
  static const cabecalho = Color(0xFFF9F4EE);
  static const trilho = Color(0xFFEAE0D2);
  static const campo = Color(0xFFEAE1D4);

  static const texto = Color(0xFF1F2D1F);
  static const textoSuave = Color(0xFF8A8778);
  static const creme = Color(0xFFF2E6D2);

  /// Cores que o usuário pode escolher para uma categoria.
  static const paletaCategorias = <Color>[
    Color(0xFF3E6A46),
    Color(0xFF7FA67B),
    Color(0xFF5A7A8A),
    Color(0xFFC98A3A),
    Color(0xFF8A7088),
    Color(0xFFB85C41),
    Color(0xFFA0785A),
    Color(0xFF4F8A8B),
    Color(0xFFD4A84B),
    Color(0xFF8A8A7A),
  ];
}

class AppTheme {
  AppTheme._();

  /// Fonte do app (assets/fonts). Os painters também a usam.
  static const fonte = 'Roboto';

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: Cores.verde,
      primary: Cores.verde,
      surface: Cores.cartao,
      error: Cores.despesa,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: fonte,
      colorScheme: esquema,
      scaffoldBackgroundColor: Cores.fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: Cores.cabecalho,
        foregroundColor: Cores.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fonte,
          color: Cores.texto,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Cores.texto,
          fontWeight: FontWeight.w800,
          fontSize: 28,
        ),
        titleMedium: TextStyle(
          color: Cores.texto,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(color: Cores.texto, fontSize: 14),
        bodySmall: TextStyle(color: Cores.textoSuave, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Cores.campo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: Cores.textoSuave),
        floatingLabelStyle: const TextStyle(
          color: Cores.textoSuave,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Cores.verde,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: fonte,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Cores.verdeEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Cores.cartao,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Cores.cartao,
        showDragHandle: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Cores.cartao,
        selectedColor: Cores.verde,
        side: const BorderSide(color: Cores.trilho, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: const TextStyle(color: Cores.texto, fontFamily: fonte),
      ),
    );
  }
}
