import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:nobolso/database/lancamento_dao.dart';
import 'package:nobolso/models/lancamento.dart';
import 'package:nobolso/models/tipo.dart';
import 'package:nobolso/services/filtro_relatorio.dart';
import 'package:nobolso/services/relatorio_pdf_service.dart';
import 'package:nobolso/services/relatorio_planilha_service.dart';
import 'package:nobolso/utils/formatadores.dart';
import 'package:nobolso/utils/moeda_input_formatter.dart';
import 'package:nobolso/utils/validadores.dart';

import 'helpers.dart';

void main() {
  setUpAll(iniciarAmbienteDeTeste);

  group('formatadores', () {
    test('moeda pt-BR', () {
      expect(Formatadores.moeda(171965), 'R\$ 1.719,65');
      expect(Formatadores.moeda(0), 'R\$ 0,00');
      expect(Formatadores.moedaComSinal(18640, positivo: false), '- R\$ 186,40');
      expect(Formatadores.mesAno(DateTime(2026, 9)), 'Setembro 2026');
    });

    test('texto → centavos', () {
      expect(Formatadores.centavosDeTexto('186,40'), 18640);
      expect(Formatadores.centavosDeTexto('1.234,5'), 123450);
      expect(Formatadores.centavosDeTexto('R\$ 50'), 5000);
      expect(Formatadores.centavosDeTexto('abc'), isNull);
      expect(Formatadores.centavosDeTexto(''), isNull);
    });

    test('período do mês', () {
      final p = Periodo.mes(DateTime(2026, 2, 14));
      expect(p.deDb, '2026-02-01');
      expect(p.ateDb, '2026-02-28');
    });
  });

  group('validadores (RF11)', () {
    test('valor', () {
      expect(Validadores.valor(''), isNotNull);
      expect(Validadores.valor('0,00'), isNotNull);
      expect(Validadores.valor('x'), isNotNull);
      expect(Validadores.valor('10,50'), isNull);
    });
    test('categoria', () {
      expect(Validadores.categoria(null), isNotNull);
      expect(Validadores.categoria(3), isNull);
    });
  });

  test('digitação do valor estilo caixa eletrônico', () {
    final f = MoedaInputFormatter();
    TextEditingValue digitar(String s) =>
        f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s));
    expect(digitar('1').text, '0,01');
    expect(digitar('18640').text, '186,40');
    expect(digitar('123456').text, '1.234,56');
    expect(digitar('').text, '');
  });

  group('exportação', () {
    final itens = [
      Lancamento(
        descricao: 'Mercado; "promoção"',
        valorCentavos: 123456,
        tipo: Tipo.despesa,
        categoriaId: 1,
        data: DateTime(2026, 9, 5),
        categoriaNome: 'Alimentação',
      ),
      Lancamento(
        descricao: 'Salário',
        valorCentavos: 420000,
        tipo: Tipo.receita,
        categoriaId: 2,
        data: DateTime(2026, 9, 1),
        categoriaNome: 'Salário',
      ),
    ];
    final filtro = FiltroRelatorio(periodo: Periodo.mes(DateTime(2026, 9)));

    test('CSV com ; e vírgula decimal, BOM e escape', () {
      final csv = RelatorioPlanilhaService.montarCsv(itens);
      final linhas = csv.trim().split('\n');
      expect(csv.startsWith('﻿'), isTrue);
      expect(linhas[0], contains('Data;Descrição;Categoria;Tipo;Valor'));
      expect(linhas[1], '05/09/2026;"Mercado; ""promoção""";Alimentação;Despesa;-1234,56');
      expect(linhas[2], '01/09/2026;Salário;Salário;Receita;4200,00');
    });

    test('XLSX gera um arquivo zip válido', () {
      final bytes = RelatorioPlanilhaService.montarXlsx(filtro, itens);
      expect(bytes.length, greaterThan(1000));
      expect(bytes.sublist(0, 2), [0x50, 0x4B]); // "PK"
    });

    test('PDF gera um documento válido, inclusive vazio', () async {
      final bytes = await RelatorioPdfService.montar(
        filtro,
        itens,
        const Totais(420000, 123456, 2),
      );
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      final vazio = await RelatorioPdfService.montar(filtro, [], const Totais(0, 0, 0));
      expect(String.fromCharCodes(vazio.sublist(0, 5)), '%PDF-');
    });

    test('PDF com fonte Roboto aceita caracteres fora do Latin-1', () async {
      ByteData ler(String f) =>
          ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync());
      final tema = pw.ThemeData.withFont(
        base: pw.Font.ttf(ler('Roboto-Regular.ttf')),
        bold: pw.Font.ttf(ler('Roboto-Bold.ttf')),
      );
      final bytes = await RelatorioPdfService.montar(
        filtro,
        [
          Lancamento(
            descricao: 'Café — padaria “Pão & Cia” € ✓',
            valorCentavos: 990,
            tipo: Tipo.despesa,
            categoriaId: 1,
            data: DateTime(2026, 9, 3),
            categoriaNome: 'Alimentação',
          ),
        ],
        const Totais(0, 990, 1),
        tema: tema,
      );
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
