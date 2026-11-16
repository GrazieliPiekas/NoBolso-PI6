import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nobolso/database/categoria_dao.dart';
import 'package:nobolso/database/configuracao_dao.dart';
import 'package:nobolso/database/database_helper.dart';
import 'package:nobolso/database/lancamento_dao.dart';
import 'package:nobolso/models/lancamento.dart';
import 'package:nobolso/models/tipo.dart';
import 'package:nobolso/services/backup_service.dart';
import 'package:nobolso/services/lancamentos_fixos_service.dart';
import 'package:nobolso/utils/formatadores.dart';
import 'package:nobolso/viewmodels/carregamento_seguro.dart';
import 'package:nobolso/viewmodels/categorias_view_model.dart';
import 'package:nobolso/viewmodels/lancamento_form_view_model.dart';
import 'package:nobolso/viewmodels/lancamentos_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

/// ViewModel mínimo só para testar o mixin de carregamento.
class _ViewModelDeTeste extends ChangeNotifier with CarregamentoSeguro {
  bool falhar = true;
  int carregados = 0;

  Future<void> carregar() => carregarComSeguranca(() async {
    if (falhar) throw Exception('banco indisponível');
    carregados++;
  });
}

/// Melhorias de robustez: erro no carregamento, desfazer exclusão,
/// copiar lançamentos fixos, backup/restauração e validação no ViewModel.
void main() {
  setUpAll(iniciarAmbienteDeTeste);
  setUp(bancoNovo);
  tearDown(() => DatabaseHelper.instance.fechar());

  final dao = LancamentoDao();

  Future<int> idCategoria(String nome, [Tipo tipo = Tipo.despesa]) async =>
      (await CategoriaDao().listar(tipo: tipo))
          .firstWhere((c) => c.nome == nome)
          .id!;

  Lancamento lancamento(
    int categoria,
    DateTime data, {
    String descricao = 'Teste',
    int centavos = 1000,
    bool fixo = false,
    Tipo tipo = Tipo.despesa,
  }) => Lancamento(
    descricao: descricao,
    valorCentavos: centavos,
    tipo: tipo,
    categoriaId: categoria,
    data: data,
    fixo: fixo,
  );

  group('carregamento seguro', () {
    test('erro vira mensagem e "tentar de novo" limpa o erro', () async {
      final viewModel = _ViewModelDeTeste();
      await viewModel.carregar();
      expect(viewModel.erro, isNotNull);
      expect(viewModel.carregados, 0);

      viewModel.falhar = false;
      await viewModel.carregar();
      expect(viewModel.erro, isNull);
      expect(viewModel.carregados, 1);
    });

    test('não quebra se o carregamento termina depois do dispose', () async {
      final viewModel = _ViewModelDeTeste()..falhar = false;
      final carregando = viewModel.carregar();
      viewModel.dispose();
      await expectLater(carregando, completes);
    });

    test('ViewModel real carrega sem erro com o banco funcionando', () async {
      final viewModel = CategoriasViewModel();
      await viewModel.carregar();
      expect(viewModel.erro, isNull);
      expect(viewModel.categorias, hasLength(9));
      viewModel.dispose();
    });
  });

  group('desfazer exclusão', () {
    test('o lançamento volta com o mesmo id e os mesmos dados', () async {
      final lazer = await idCategoria('Lazer');
      final id = await dao.inserir(
        lancamento(lazer, DateTime(2026, 3, 10), descricao: 'Cinema'),
      );
      final original = (await dao.listar()).single;

      final viewModel = LancamentosViewModel();
      await viewModel.carregar();
      await viewModel.excluir(original);
      expect(await dao.contar(), 0);

      await viewModel.desfazerExclusao(original);
      final volta = (await dao.listar()).single;
      expect(volta.id, id);
      expect(volta.descricao, 'Cinema');
      expect(volta.valorCentavos, 1000);
      expect(volta.data, DateTime(2026, 3, 10));
      viewModel.dispose();
    });
  });

  group('copiar fixos do mês anterior', () {
    test('copia só os fixos, no mesmo dia, ajustando o dia 31', () async {
      final moradia = await idCategoria('Moradia');
      final lazer = await idCategoria('Lazer');
      final salario = await idCategoria('Salário', Tipo.receita);
      await dao.inserirVarios([
        lancamento(
          moradia,
          DateTime(2026, 1, 5),
          descricao: 'Aluguel',
          fixo: true,
        ),
        lancamento(
          salario,
          DateTime(2026, 1, 31),
          descricao: 'Salário',
          tipo: Tipo.receita,
          fixo: true,
        ),
        lancamento(lazer, DateTime(2026, 1, 20), descricao: 'Show'),
      ]);

      final copiados = await LancamentosFixosService().copiarDoMesAnterior(
        DateTime(2026, 2, 1),
      );
      expect(copiados, 2);

      final fevereiro = await dao.listar(
        periodo: Periodo.mes(DateTime(2026, 2)),
      );
      expect(
        fevereiro.map((l) => l.descricao),
        unorderedEquals(['Aluguel', 'Salário']),
      );
      expect(fevereiro.every((l) => l.fixo), isTrue);
      expect(
        fevereiro.firstWhere((l) => l.descricao == 'Salário').data,
        DateTime(2026, 2, 28),
        reason: 'fevereiro de 2026 não tem dia 31',
      );
      expect(
        fevereiro.firstWhere((l) => l.descricao == 'Aluguel').data,
        DateTime(2026, 2, 5),
      );
    });

    test('rodar duas vezes não duplica', () async {
      final moradia = await idCategoria('Moradia');
      await dao.inserir(
        lancamento(
          moradia,
          DateTime(2026, 4, 10),
          descricao: 'Aluguel',
          fixo: true,
        ),
      );
      final servico = LancamentosFixosService();
      expect(await servico.copiarDoMesAnterior(DateTime(2026, 5)), 1);
      expect(await servico.copiarDoMesAnterior(DateTime(2026, 5)), 0);
      expect(
        await dao.listar(periodo: Periodo.mes(DateTime(2026, 5))),
        hasLength(1),
      );
    });

    test('mês anterior sem fixos não cria nada', () async {
      expect(
        await LancamentosFixosService().copiarDoMesAnterior(DateTime(2026, 7)),
        0,
      );
    });
  });

  group('backup e restauração', () {
    late Directory pasta;

    setUp(() async {
      // Backup copia o arquivo, então aqui o banco precisa estar em disco.
      pasta = await Directory.systemTemp.createTemp('nobolso_teste_');
      await DatabaseHelper.instance.fechar();
      DatabaseHelper.instance.caminhoPersonalizado =
          '${pasta.path}${Platform.pathSeparator}nobolso.db';
    });

    tearDown(() async {
      await DatabaseHelper.instance.fechar();
      await pasta.delete(recursive: true);
    });

    test('restaurar devolve os dados do momento do backup', () async {
      final lazer = await idCategoria('Lazer');
      await dao.inserir(
        lancamento(lazer, DateTime(2026, 6, 1), descricao: 'Antes'),
      );
      await ConfiguracaoDao().salvarNome('Grazi');

      final servico = BackupService();
      final backup = await servico.gerarBackup(
        pasta: pasta,
        hoje: DateTime(2026, 6, 2),
      );
      expect(backup.path, endsWith('nobolso_backup_2026-06-02.db'));

      // Depois do backup a pessoa mexe nos dados...
      await dao.excluirTodos();
      await dao.inserir(
        lancamento(lazer, DateTime(2026, 6, 3), descricao: 'Depois'),
      );
      await ConfiguracaoDao().salvarNome('Outro');

      // ...e restaura: volta tudo como estava.
      await servico.restaurar(backup);
      final lista = await dao.listar();
      expect(lista.map((l) => l.descricao), ['Antes']);
      expect(await ConfiguracaoDao().nomeUsuario(), 'Grazi');
    });

    test(
      'arquivo que não é banco é recusado e os dados ficam intactos',
      () async {
        final lazer = await idCategoria('Lazer');
        await dao.inserir(lancamento(lazer, DateTime(2026, 6, 1)));
        final falso = File('${pasta.path}${Platform.pathSeparator}foto.db')
          ..writeAsStringSync('isto não é um SQLite');

        await expectLater(
          BackupService().restaurar(falso),
          throwsA(isA<BackupInvalidoException>()),
        );
        expect(await dao.contar(), 1);
      },
    );

    test('banco SQLite de outro app é recusado', () async {
      final outro = '${pasta.path}${Platform.pathSeparator}outro.db';
      final db = await databaseFactoryFfi.openDatabase(outro);
      await db.execute('CREATE TABLE contatos (id INTEGER)');
      await db.close();

      await expectLater(
        BackupService().validar(File(outro)),
        throwsA(isA<BackupInvalidoException>()),
      );
    });

    test('backup de versão mais nova do app é recusado', () async {
      final backup = await BackupService().gerarBackup(pasta: pasta);
      final db = await databaseFactoryFfi.openDatabase(backup.path);
      await db.setVersion(DatabaseHelper.versao + 1);
      await db.close();

      await expectLater(
        BackupService().validar(backup),
        throwsA(
          isA<BackupInvalidoException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('versão mais nova'),
          ),
        ),
      );
    });
  });

  group('formulário de lançamento (ViewModel)', () {
    test(
      'sem valor e sem categoria não salva e mostra os dois erros',
      () async {
        final viewModel = LancamentoFormViewModel();
        await viewModel.carregarCategorias();
        final resultado = await viewModel.salvar(
          valorTexto: '',
          descricaoTexto: '',
        );
        expect(resultado, isNull);
        expect(viewModel.erroValor, 'Informe um valor');
        expect(viewModel.erroCategoria, 'Escolha uma categoria');
        expect(await dao.contar(), 0);
        viewModel.dispose();
      },
    );

    test('descrição vazia usa o nome da categoria', () async {
      final viewModel = LancamentoFormViewModel();
      await viewModel.carregarCategorias();
      viewModel.escolherCategoria(await idCategoria('Saúde'));
      final resultado = await viewModel.salvar(
        valorTexto: '45,90',
        descricaoTexto: '   ',
      );
      expect(resultado, isNotNull);
      final salvo = (await dao.listar()).single;
      expect(salvo.descricao, 'Saúde');
      expect(salvo.valorCentavos, 4590);
      viewModel.dispose();
    });

    test('trocar para receita limpa a categoria e só lista receitas', () async {
      final viewModel = LancamentoFormViewModel();
      await viewModel.carregarCategorias();
      viewModel.escolherCategoria(await idCategoria('Lazer'));
      viewModel.trocarTipo(Tipo.receita);
      await viewModel.carregarCategorias();
      expect(viewModel.categoriaId, isNull);
      expect(viewModel.categorias.every((c) => c.tipo == Tipo.receita), isTrue);
      viewModel.dispose();
    });
  });
}
