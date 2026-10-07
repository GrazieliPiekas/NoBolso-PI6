import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'services/notificacao_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No Windows (usado só para desenvolver) o SQLite roda via FFI.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  await NotificacaoService.instance.inicializar();

  runApp(const NoBolsoApp());
}
