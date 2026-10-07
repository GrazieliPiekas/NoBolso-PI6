import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:nobolso/graphics/curvas.dart';
import 'package:nobolso/graphics/viewport.dart';
import 'package:nobolso/painters/barras_painter.dart';
import 'package:nobolso/painters/linha_painter.dart';
import 'package:nobolso/painters/mapa_calor_painter.dart';
import 'package:nobolso/painters/medidor_painter.dart';
import 'package:nobolso/painters/rosca_painter.dart';
import 'package:nobolso/services/dados_graficos_service.dart';
import 'package:nobolso/utils/formatadores.dart';

import 'helpers.dart';

void main() {
  setUpAll(iniciarAmbienteDeTeste);

  group('viewport', () {
    final vp = Viewport(
      area: const Rect.fromLTWH(10, 20, 200, 100),
      xMin: 0,
      xMax: 10,
      yMin: 0,
      yMax: 50,
    );

    test('cantos do mundo caem nos cantos da área (Y invertido)', () {
      expect(vp.paraTela(0, 0), const Offset(10, 120));
      expect(vp.paraTela(10, 50), const Offset(210, 20));
      expect(vp.paraTela(5, 25), const Offset(110, 70));
    });

    test('intervalo degenerado não divide por zero', () {
      final v = Viewport(area: const Rect.fromLTWH(0, 0, 100, 100), xMin: 3, xMax: 3, yMin: 0, yMax: 0);
      expect(v.xTela(3).isFinite, isTrue);
      expect(v.yTela(0).isFinite, isTrue);
    });

    test('máximo agradável', () {
      expect(Viewport.maximoAgradavel(0), 1);
      expect(Viewport.maximoAgradavel(87), 100);
      expect(Viewport.maximoAgradavel(1719.65), 2000);
      expect(Viewport.maximoAgradavel(230), 250);
      expect(Viewport.maximoAgradavel(410), 500);
    });

    test('eixo agradável cobre o intervalo com passos redondos', () {
      expect(Viewport.eixoAgradavel(-200, 4900), (-2000.0, 6000.0, 2000.0));
      expect(Viewport.eixoAgradavel(0, 87), (0.0, 100.0, 25.0));
      expect(Viewport.eixoAgradavel(0, 0), (0.0, 1.0, 0.25));
      final (lo, hi, passo) = Viewport.eixoAgradavel(-1234, -10);
      expect(lo, lessThanOrEqualTo(-1234));
      expect(hi, 0);
      expect((hi - lo) / passo, lessThanOrEqualTo(4));
    });
  });

  group('curvas', () {
    test('controles Catmull-Rom → Bézier seguem a fórmula do plano', () {
      const p = [Offset(0, 0), Offset(6, 6), Offset(12, 0), Offset(18, 6)];
      final c = controlesCatmullRom(p);
      expect(c, hasLength(3));
      // Trecho 1→2: C1 = P1 + (P2 − P0)/6 ; C2 = P2 − (P3 − P1)/6
      expect(c[1].$1, const Offset(6 + 12 / 6, 6 + 0 / 6));
      expect(c[1].$2, const Offset(12 - 12 / 6, 0 - 0 / 6));
    });

    test('easing Bézier: extremos fixos e crescimento monótono', () {
      const e = EasingBezier.suave;
      expect(e.transform(0), 0);
      expect(e.transform(1), 1);
      var anterior = 0.0;
      for (var i = 1; i <= 100; i++) {
        final v = e.transform(i / 100);
        expect(v, greaterThanOrEqualTo(anterior - 1e-9));
        anterior = v;
      }
      // Curva linear (0,0,1,1) deve dar a identidade.
      const linear = EasingBezier(0, 0, 1, 1);
      expect(linear.transform(0.37), closeTo(0.37, 1e-4));
    });
  });

  group('dados dos gráficos', () {
    test('saldo acumulado por mês (filtro Ano)', () {
      final p = Periodo.ultimosMeses(DateTime(2026, 9, 15), 12);
      final s = DadosGraficosService.serieSaldo(
        FiltroAnalise.ano,
        p,
        {
          '2026-08-10': (100000, 20000),
          '2026-09-01': (0, 30000),
        },
        DateTime(2026, 9, 15),
      );
      expect(s.valores, hasLength(12));
      expect(s.valores[10], 800); // agosto: +800
      expect(s.valores[11], 500); // setembro: 800 − 300
      expect(s.rotulos.last, 'Set');
    });

    test('mapa de calor do mês: semanas × 7 dias, fora do mês = null', () {
      // Setembro/2026 começa numa terça.
      final p = Periodo.mes(DateTime(2026, 9));
      final m = DadosGraficosService.matrizCalor(
        FiltroAnalise.mes,
        p,
        {'2026-09-05': (0, 5000)},
      );
      expect(m.valores, hasLength(5));
      expect(m.valores[0][0], isNull); // segunda 31/08
      expect(m.valores[0][1], 0); // terça 01/09
      expect(m.valores[0][5], 50); // sábado 05/09
      expect(m.maximo, 50);
    });
  });

  testWidgets('os 5 painters desenham sem erro em vários tamanhos', (t) async {
    final serie = const SerieLinha([0, -50, 120, 300, 280], ['Jan', '', 'Mar', '', 'Mai']);
    final matriz = DadosGraficosService.matrizCalor(
      FiltroAnalise.mes,
      Periodo.mes(DateTime(2026, 9)),
      {'2026-09-05': (0, 5000), '2026-09-10': (0, 100)},
    );
    final painters = <CustomPainter>[
      BarrasPainter(const [
        ItemBarra('Alimentação', 574, Colors.green),
        ItemBarra('Transporte', 180, Colors.blue),
        ItemBarra('Lazer com nome bem comprido', 336, Colors.orange),
      ]),
      LinhaPainter(serie),
      RoscaPainter(
        const [FatiaRosca(4200, Colors.green), FatiaRosca(1719, Colors.red)],
        textoCentro: 'R\$ 2.481',
        subtextoCentro: 'saldo',
      ),
      RoscaPainter(const [], textoCentro: '0', subtextoCentro: 'vazio'),
      MedidorPainter(0.68),
      MedidorPainter(1.4),
      MapaCalorPainter(matriz),
    ];
    for (final tamanho in const [Size(320, 200), Size(160, 120), Size(600, 300)]) {
      for (final p in painters) {
        await t.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox.fromSize(
                size: tamanho,
                child: CustomPaint(painter: p),
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull);
      }
    }
  });
}
