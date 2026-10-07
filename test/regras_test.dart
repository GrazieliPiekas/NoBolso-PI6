import 'package:flutter_test/flutter_test.dart';
import 'package:nobolso/database/categoria_dao.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:nobolso/database/lancamento_dao.dart';
import 'package:nobolso/database/orcamento_dao.dart';
import 'package:nobolso/models/lancamento.dart';
import 'package:nobolso/models/orcamento.dart';
import 'package:nobolso/models/tipo.dart';
import 'package:nobolso/services/orcamento_service.dart';
import 'package:nobolso/services/recomendacao_service.dart';

import 'helpers.dart';

void main() {
  setUpAll(iniciarAmbienteDeTeste);
  setUp(bancoNovo);
  tearDown(() => DatabaseHelper.instance.fechar());

  group('níveis de orçamento', () {
    test('50 / 80 / 100%', () {
      expect(OrcamentoService.nivelAtingido(0.49), 0);
      expect(OrcamentoService.nivelAtingido(0.5), 50);
      expect(OrcamentoService.nivelAtingido(0.79), 50);
      expect(OrcamentoService.nivelAtingido(0.8), 80);
      expect(OrcamentoService.nivelAtingido(1.0), 100);
      expect(OrcamentoService.nivelAtingido(1.7), 100);
    });

    test('mensagens não punitivas', () {
      final s = StatusOrcamento(
        const Orcamento(id: 1, categoriaId: 2, limiteCentavos: 35000, categoriaNome: 'Lazer'),
        33600,
      );
      final (titulo, corpo) = OrcamentoService.mensagemAlerta(s, 80);
      expect(titulo, contains('Lazer'));
      expect(corpo, contains('R\$ 14,00'));
      final todas = [50, 80, 100]
          .map((n) => OrcamentoService.mensagemAlerta(s, n))
          .expand((m) => [m.$1, m.$2])
          .join(' ')
          .toLowerCase();
      for (final palavra in ['estourou', 'irresponsável', 'culpa', 'erro']) {
        expect(todas, isNot(contains(palavra)));
      }
    });
  });

  test('alertas: cada nível só uma vez por mês; pular níveis avisa só o maior', () async {
    final hoje = DateTime(2026, 9, 15);
    final lazer = (await CategoriaDao().listar(tipo: Tipo.despesa))
        .firstWhere((c) => c.nome == 'Lazer')
        .id!;
    await OrcamentoDao().inserir(Orcamento(categoriaId: lazer, limiteCentavos: 10000));
    final servico = OrcamentoService();
    final dao = LancamentoDao();
    Future<void> gastar(int c) => dao.inserir(
      Lancamento(
        descricao: 'x',
        valorCentavos: c,
        tipo: Tipo.despesa,
        categoriaId: lazer,
        data: hoje,
      ),
    );

    await gastar(4000); // 40%
    expect(await servico.verificarAlertas(hoje: hoje), isEmpty);

    await gastar(1500); // 55%
    expect(await servico.verificarAlertas(hoje: hoje), hasLength(1));
    expect(await servico.verificarAlertas(hoje: hoje), isEmpty); // não repete

    await gastar(5000); // 105%: pula o 80 e avisa só o 100
    final m = await servico.verificarAlertas(hoje: hoje);
    expect(m, hasLength(1));
    expect(m.single, contains('limite'));
    expect(await servico.verificarAlertas(hoje: hoje), isEmpty);
  });

  test('resumo: medidor usa a soma das categorias quando não há geral', () async {
    final cats = await CategoriaDao().listar(tipo: Tipo.despesa);
    await OrcamentoDao().inserir(Orcamento(categoriaId: cats[0].id, limiteCentavos: 1000));
    await OrcamentoDao().inserir(Orcamento(categoriaId: cats[1].id, limiteCentavos: 3000));
    var r = await OrcamentoService().resumo(DateTime(2026, 9));
    expect(r.medidorPelaSoma, isTrue);
    expect(r.limiteMedidor, 4000);

    await OrcamentoDao().inserir(const Orcamento(limiteCentavos: 2000));
    r = await OrcamentoService().resumo(DateTime(2026, 9));
    expect(r.medidorPelaSoma, isFalse);
    expect(r.limiteMedidor, 2000);
    expect(r.somaExcedeGeral, isTrue);
  });

  group('recomendações por regras', () {
    test('sem dados: mensagem neutra', () {
      final r = RecomendacaoService.aplicarRegras(
        totais: const Totais(0, 0, 0),
        porCategoria: const [],
        porDia: const {},
        orcamentosDoMes: const [],
      );
      expect(r.single.titulo, 'Ainda sem recomendações');
    });

    test('as quatro regras disparam', () {
      final r = RecomendacaoService.aplicarRegras(
        totais: const Totais(1000, 5000, 4),
        porCategoria: const [
          TotalCategoria(1, 'Lazer', 0, 3000),
          TotalCategoria(2, 'Moradia', 0, 2000),
        ],
        // 2026-09-05 e 2026-09-12 são sábados.
        porDia: const {
          '2026-09-05': (0, 2000),
          '2026-09-12': (0, 1000),
          '2026-09-07': (1000, 2000),
        },
        orcamentosDoMes: [
          StatusOrcamento(
            const Orcamento(id: 1, categoriaId: 1, limiteCentavos: 3500, categoriaNome: 'Lazer'),
            3360,
          ),
        ],
      );
      final titulos = r.map((x) => x.titulo).toList();
      expect(titulos, contains('Despesas acima das receitas'));
      expect(titulos, contains('Lazer chegou a 96% do limite'));
      expect(titulos, contains('Maior gasto: Lazer'));
      expect(titulos, contains('Sábado concentra 60% dos gastos'));
    });
  });
}
