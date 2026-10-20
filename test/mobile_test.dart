import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nobolso/database/categoria_dao.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:nobolso/database/lancamento_dao.dart';
import 'package:nobolso/models/lancamento.dart';
import 'package:nobolso/models/tipo.dart';
import 'package:nobolso/viewmodels/lancamentos_view_model.dart';
import 'package:nobolso/viewmodels/tutorial_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

/// Requisitos do Trabalho Final de Mobile: campo booleano, migração do banco
/// e busca em tempo real na ViewModel.
void main() {
  setUpAll(iniciarAmbienteDeTeste);
  setUp(bancoNovo);
  tearDown(() => DatabaseHelper.instance.fechar());

  Future<int> idCategoria(String nome) async =>
      (await CategoriaDao().listar(tipo: Tipo.despesa))
          .firstWhere((c) => c.nome == nome)
          .id!;

  test('campo booleano "fixo" é gravado e lido', () async {
    final dao = LancamentoDao();
    final moradia = await idCategoria('Moradia');
    final hoje = DateTime.now();
    await dao.inserir(
      Lancamento(
        descricao: 'Aluguel',
        valorCentavos: 150000,
        tipo: Tipo.despesa,
        categoriaId: moradia,
        data: hoje,
        fixo: true,
      ),
    );
    await dao.inserir(
      Lancamento(
        descricao: 'Pizza',
        valorCentavos: 6000,
        tipo: Tipo.despesa,
        categoriaId: moradia,
        data: hoje,
      ),
    );
    final l = await dao.listar();
    expect(l.firstWhere((x) => x.descricao == 'Aluguel').fixo, isTrue);
    expect(l.firstWhere((x) => x.descricao == 'Pizza').fixo, isFalse);
  });

  test('banco v1 é migrado para v2 sem perder lançamentos', () async {
    final pasta = await Directory.systemTemp.createTemp('nobolso_');
    final caminho = '${pasta.path}${Platform.pathSeparator}v1.db';
    // Banco como era na versão 1 (sem a coluna fixo).
    final v1 = await databaseFactory.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE categorias (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'nome TEXT NOT NULL, tipo TEXT NOT NULL, cor INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE lancamentos (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'descricao TEXT NOT NULL, valor_centavos INTEGER NOT NULL, '
            'tipo TEXT NOT NULL, categoria_id INTEGER NOT NULL, data TEXT NOT NULL)',
          );
          await db.insert('categorias', {
            'nome': 'Moradia',
            'tipo': 'despesa',
            'cor': 0,
          });
          await db.insert('lancamentos', {
            'descricao': 'Aluguel',
            'valor_centavos': 100,
            'tipo': 'despesa',
            'categoria_id': 1,
            'data': '2026-10-01',
          });
        },
      ),
    );
    await v1.close();

    await DatabaseHelper.instance.fechar();
    DatabaseHelper.instance.caminhoPersonalizado = caminho;
    final l = await LancamentoDao().listar();
    expect(l, hasLength(1));
    expect(l.single.fixo, isFalse);

    await DatabaseHelper.instance.fechar();
    await pasta.delete(recursive: true);
  });

  test(
    'busca da lista filtra em tempo real, sem acento e por categoria',
    () async {
      final dao = LancamentoDao();
      final hoje = DateTime.now();
      Future<void> despesa(
        String desc,
        String cat, {
        bool fixo = false,
      }) async => dao.inserir(
        Lancamento(
          descricao: desc,
          valorCentavos: 1000,
          tipo: Tipo.despesa,
          categoriaId: await idCategoria(cat),
          data: hoje,
          fixo: fixo,
        ),
      );
      await despesa('Farmácia', 'Saúde');
      await despesa('Mercado', 'Alimentação');
      await despesa('Aluguel', 'Moradia', fixo: true);

      final vm = LancamentosViewModel();
      await vm.carregar();
      expect(vm.itens, hasLength(3));

      vm.buscar('farm');
      expect(vm.itens!.map((l) => l.descricao), ['Farmácia']);

      vm.buscar('saude'); // sem acento, pelo nome da categoria
      expect(vm.itens!.map((l) => l.descricao), ['Farmácia']);

      vm.buscar('');
      vm.alternarSomenteFixos(true);
      expect(vm.itens!.map((l) => l.descricao), ['Aluguel']);
      expect(vm.totais!.despesas, 1000);
      vm.dispose();
    },
  );

  test('tutorial: 5 passos, aparece só até ser concluído', () async {
    expect(await TutorialViewModel.precisaMostrar(), isTrue);

    final tutorial = TutorialViewModel();
    expect(tutorial.contador, '1 de 5');
    expect(tutorial.passoAtual.alvo, AlvoTutorial.botaoNovo);
    for (var i = 0; i < 4; i++) {
      expect(tutorial.avancar(), isFalse);
    }
    expect(tutorial.contador, '5 de 5');
    expect(tutorial.avancar(), isTrue); // no último passo, avançar fecha

    await tutorial.concluir();
    expect(await TutorialViewModel.precisaMostrar(), isFalse);
    tutorial.dispose();
  });
}
