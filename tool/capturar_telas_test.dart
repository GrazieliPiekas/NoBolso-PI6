// Gera capturas PNG das telas reais com dados fictícios, sem emulador.
// Uso:  flutter test tool/capturar_telas_test.dart
// Saída: build/telas/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nobolso/app.dart';
import 'package:nobolso/database/categoria_dao.dart';
import 'package:nobolso/database/configuracao_dao.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:nobolso/database/orcamento_dao.dart';
import 'package:nobolso/models/orcamento.dart';
import 'package:nobolso/models/tipo.dart';
import 'package:nobolso/screens/boas_vindas_screen.dart';
import 'package:nobolso/screens/lancamento_form_screen.dart';
import 'package:nobolso/services/gerador_dados_service.dart';
import 'package:nobolso/theme/app_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _carregarFonte(String familia, List<String> arquivos) async {
  final loader = FontLoader(familia);
  for (final a in arquivos) {
    final bytes = File(a).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  final chave = GlobalKey();

  setUpAll(() async {
    sqfliteFfiInit();
    // Sem isolate: as consultas terminam dentro do relógio falso do teste.
    databaseFactory = databaseFactoryFfiNoIsolate;
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
    await _carregarFonte('Roboto', [
      'assets/fonts/Roboto-Regular.ttf',
      'assets/fonts/Roboto-Bold.ttf',
    ]);
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter';
    await _carregarFonte('MaterialIcons', [
      '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    ]);
    Directory('build/telas').createSync(recursive: true);
  });

  Future<void> semear() async {
    await DatabaseHelper.instance.fechar();
    DatabaseHelper.instance.caminhoPersonalizado = inMemoryDatabasePath;
    final cfg = ConfiguracaoDao();
    await cfg.salvarNome('Grazi');
    await cfg.marcarBoasVindasVista();
    await GeradorDadosService().gerar(900, semente: 7);
    final cats = await CategoriaDao().listar(tipo: Tipo.despesa);
    final dao = OrcamentoDao();
    await dao.inserir(const Orcamento(limiteCentavos: 900000));
    for (final (nome, limite) in [
      ('Moradia', 300000),
      ('Alimentação', 150000),
      ('Lazer', 60000),
      ('Transporte', 120000),
    ]) {
      await dao.inserir(
        Orcamento(
          categoriaId: cats.firstWhere((c) => c.nome == nome).id,
          limiteCentavos: limite,
        ),
      );
    }
  }

  Future<void> capturar(WidgetTester t, String nome) async {
    await t.pump(const Duration(seconds: 2));
    await t.runAsync(() async {
      final boundary =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/telas/$nome.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Widget envolver(Widget home) => RepaintBoundary(
    key: chave,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );

  testWidgets('capturas', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await semear();

    await t.pumpWidget(envolver(BoasVindasScreen(onConcluir: () {})));
    await t.runAsync(() => precacheImage(
      const AssetImage('assets/images/icone_nobolso.png'),
      t.element(find.byType(BoasVindasScreen)),
    ));
    await capturar(t, '0_boas_vindas');

    await t.pumpWidget(envolver(const NavegacaoPrincipal()));
    await t.pump(const Duration(milliseconds: 300));
    await capturar(t, '1_inicio');

    for (final (rotulo, nome) in [
      ('Análise', '2_analise'),
      ('Orçamento', '3_orcamentos'),
      ('Relatórios', '5_relatorios'),
    ]) {
      await t.tap(find.text(rotulo));
      await t.pump(const Duration(milliseconds: 300));
      await capturar(t, nome);
    }

    await t.pumpWidget(envolver(const LancamentoFormScreen()));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextField).first, '18640');
    await t.tap(find.text('Alimentação'));
    await capturar(t, '4_novo_lancamento');

    await t.pumpWidget(const SizedBox());
    await DatabaseHelper.instance.fechar();
  });
}
