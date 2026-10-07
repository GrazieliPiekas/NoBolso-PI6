import 'package:flutter_test/flutter_test.dart';
import 'package:nobolso/database/categoria_dao.dart';
import 'package:nobolso/database/configuracao_dao.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:nobolso/database/lancamento_dao.dart';
import 'package:nobolso/database/orcamento_dao.dart';
import 'package:nobolso/models/categoria.dart';
import 'package:nobolso/models/lancamento.dart';
import 'package:nobolso/models/orcamento.dart';
import 'package:nobolso/models/tipo.dart';
import 'package:nobolso/utils/formatadores.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

void main() {
  setUpAll(iniciarAmbienteDeTeste);
  setUp(bancoNovo);
  tearDown(() => DatabaseHelper.instance.fechar());

  final categorias = CategoriaDao();
  final lancamentos = LancamentoDao();
  final orcamentos = OrcamentoDao();

  Future<int> idCategoria(String nome, Tipo tipo) async =>
      (await categorias.listar(tipo: tipo)).firstWhere((c) => c.nome == nome).id!;

  Lancamento despesa(int cat, int centavos, DateTime data) => Lancamento(
    descricao: 'Teste',
    valorCentavos: centavos,
    tipo: Tipo.despesa,
    categoriaId: cat,
    data: data,
  );

  group('categorias', () {
    test('cria as 9 categorias padrão (7 despesa + 2 receita)', () async {
      expect(await categorias.listar(), hasLength(9));
      expect(await categorias.listar(tipo: Tipo.despesa), hasLength(7));
      expect(await categorias.listar(tipo: Tipo.receita), hasLength(2));
    });

    test('nome repetido no mesmo tipo é recusado', () async {
      expect(
        () => categorias.inserir(
          const Categoria(nome: 'Lazer', tipo: Tipo.despesa, cor: 0),
        ),
        throwsA(isA<CategoriaDuplicadaException>()),
      );
    });

    test('mesmo nome em tipos diferentes é permitido ("Outros")', () async {
      final outros = (await categorias.listar()).where((c) => c.nome == 'Outros');
      expect(outros, hasLength(2));
    });

    test('excluir categoria com lançamento é bloqueado', () async {
      final lazer = await idCategoria('Lazer', Tipo.despesa);
      await lancamentos.inserir(despesa(lazer, 1000, DateTime(2026, 9, 1)));
      expect(
        () => categorias.excluir(lazer),
        throwsA(isA<CategoriaEmUsoException>()),
      );
    });

    test('excluir categoria com orçamento é bloqueado', () async {
      final saude = await idCategoria('Saúde', Tipo.despesa);
      await orcamentos.inserir(Orcamento(categoriaId: saude, limiteCentavos: 100));
      expect(
        () => categorias.excluir(saude),
        throwsA(isA<CategoriaEmUsoException>()),
      );
    });

    test('excluir categoria sem uso funciona', () async {
      final id = await categorias.inserir(
        const Categoria(nome: 'Pets', tipo: Tipo.despesa, cor: 0xFF000000),
      );
      await categorias.excluir(id);
      expect(await categorias.buscar(id), isNull);
    });
  });

  group('lançamentos', () {
    test('valor zero é recusado pelo CHECK do banco', () async {
      final cat = await idCategoria('Lazer', Tipo.despesa);
      expect(
        () => lancamentos.inserir(despesa(cat, 0, DateTime(2026, 9, 1))),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('totais e filtro por período usam BETWEEN nas datas', () async {
      final lazer = await idCategoria('Lazer', Tipo.despesa);
      final salario = await idCategoria('Salário', Tipo.receita);
      await lancamentos.inserir(despesa(lazer, 2500, DateTime(2026, 9, 1)));
      await lancamentos.inserir(despesa(lazer, 1500, DateTime(2026, 9, 30)));
      await lancamentos.inserir(despesa(lazer, 9999, DateTime(2026, 10, 1)));
      await lancamentos.inserir(
        Lancamento(
          descricao: 'Salário',
          valorCentavos: 420000,
          tipo: Tipo.receita,
          categoriaId: salario,
          data: DateTime(2026, 9, 5),
        ),
      );
      final t = await lancamentos.totais(periodo: Periodo.mes(DateTime(2026, 9)));
      expect(t.despesas, 4000);
      expect(t.receitas, 420000);
      expect(t.saldo, 416000);
      expect(t.quantidade, 3);

      final lista = await lancamentos.listar(
        periodo: Periodo.mes(DateTime(2026, 9)),
        tipo: Tipo.despesa,
      );
      expect(lista, hasLength(2));
      expect(lista.first.data, DateTime(2026, 9, 30)); // mais recente primeiro
      expect(lista.first.categoriaNome, 'Lazer');
    });

    test('atualizar e excluir', () async {
      final cat = await idCategoria('Lazer', Tipo.despesa);
      final id = await lancamentos.inserir(despesa(cat, 100, DateTime(2026, 9, 1)));
      await lancamentos.atualizar(
        Lancamento(
          id: id,
          descricao: 'Editado',
          valorCentavos: 200,
          tipo: Tipo.despesa,
          categoriaId: cat,
          data: DateTime(2026, 9, 2),
        ),
      );
      final l = (await lancamentos.listar()).single;
      expect(l.descricao, 'Editado');
      expect(l.valorCentavos, 200);
      await lancamentos.excluir(id);
      expect(await lancamentos.contar(), 0);
    });
  });

  group('orçamentos', () {
    test('só pode existir um orçamento geral', () async {
      await orcamentos.inserir(const Orcamento(limiteCentavos: 100));
      expect(
        () => orcamentos.inserir(const Orcamento(limiteCentavos: 200)),
        throwsA(isA<OrcamentoDuplicadoException>()),
      );
    });

    test('um orçamento por categoria', () async {
      final lazer = await idCategoria('Lazer', Tipo.despesa);
      await orcamentos.inserir(Orcamento(categoriaId: lazer, limiteCentavos: 1));
      expect(
        () => orcamentos.inserir(Orcamento(categoriaId: lazer, limiteCentavos: 2)),
        throwsA(isA<OrcamentoDuplicadoException>()),
      );
    });

    test('alerta é registrado uma única vez por nível e mês', () async {
      final id = await orcamentos.inserir(const Orcamento(limiteCentavos: 100));
      await orcamentos.registrarAlerta(id, '2026-09', 50);
      await orcamentos.registrarAlerta(id, '2026-09', 50);
      expect(await orcamentos.niveisEnviados(id, '2026-09'), {50});
      expect(await orcamentos.niveisEnviados(id, '2026-10'), isEmpty);
    });
  });

  test('configurações: nome e boas-vindas', () async {
    final c = ConfiguracaoDao();
    expect(await c.boasVindasVista(), isFalse);
    expect(await c.nomeUsuario(), isNull);
    await c.salvarNome('  Grazi ');
    await c.marcarBoasVindasVista();
    expect(await c.nomeUsuario(), 'Grazi');
    expect(await c.boasVindasVista(), isTrue);
  });
}
