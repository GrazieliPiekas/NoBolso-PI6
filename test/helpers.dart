import 'package:intl/date_symbol_data_local.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Inicializa SQLite via FFI e intl pt_BR. Chamar em setUpAll.
Future<void> iniciarAmbienteDeTeste() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await initializeDateFormatting('pt_BR');
}

/// Banco novo e vazio (em memória) para cada teste.
Future<void> bancoNovo() async {
  await DatabaseHelper.instance.fechar();
  DatabaseHelper.instance.caminhoPersonalizado = inMemoryDatabasePath;
}
