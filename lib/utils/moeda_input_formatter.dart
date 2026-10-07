import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Digitação estilo caixa eletrônico: "18640" vira "186,40" enquanto se digita.
/// Deixa o fluxo curto (RF12): não é preciso digitar a vírgula.
class MoedaInputFormatter extends TextInputFormatter {
  static final _fmt = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  static String formatar(int centavos) => _fmt.format(centavos / 100);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return const TextEditingValue();
    // Máximo de 11 dígitos (até R$ 999.999.999,99).
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
    final texto = formatar(int.parse(limitado));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
