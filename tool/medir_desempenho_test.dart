// Mede o tempo de inserção e das consultas dos gráficos com muitos lançamentos.
// Uso: flutter test tool/medir_desempenho_test.dart
// Roda no computador (SQLite via FFI); no celular os tempos podem ser diferentes.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:nobolso/services/dados_graficos_service.dart';
import 'package:nobolso/services/gerador_dados_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('pt_BR');
  });

  for (final n in const [100, 1000, 10000]) {
    test('$n lançamentos', () async {
      await DatabaseHelper.instance.fechar();
      DatabaseHelper.instance.caminhoPersonalizado = inMemoryDatabasePath;
      final insercao = await GeradorDadosService().gerar(n, semente: 1);

      final servico = DadosGraficosService();
      final medidas = <String, int>{};
      Future<void> medir(String nome, Future<void> Function() f) async {
        final tempos = <int>[];
        for (var i = 0; i < 5; i++) {
          final s = Stopwatch()..start();
          await f();
          tempos.add(s.elapsedMicroseconds);
        }
        tempos.sort();
        medidas[nome] = tempos[2]; // mediana de 5 execuções
      }

      await medir('inicio', () => servico.inicio(DateTime.now()));
      for (final f in FiltroAnalise.values) {
        await medir('analise_${f.name}', () => servico.analise(f));
      }
      // ignore: avoid_print
      print(
        'N=$n | insercao=${insercao.inMilliseconds} ms | '
        '${medidas.entries.map((e) => '${e.key}=${(e.value / 1000).toStringAsFixed(1)} ms').join(' | ')}',
      );
      await DatabaseHelper.instance.fechar();
    });
  }
}
