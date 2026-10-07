import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../utils/formatadores.dart';
import 'filtro_relatorio.dart';

enum FormatoPlanilha { xlsx, csv }

/// Exportação em .xlsx e .csv (decisão 8). O CSV usa `;` e vírgula decimal
/// para abrir direto no Excel em português.
class RelatorioPlanilhaService {
  final LancamentoDao _dao;
  RelatorioPlanilhaService([LancamentoDao? dao])
    : _dao = dao ?? LancamentoDao();

  static const cabecalho = ['Data', 'Descrição', 'Categoria', 'Tipo', 'Valor (R\$)'];

  Future<File> gerar(FiltroRelatorio f, FormatoPlanilha formato) async {
    final itens = await _dao.listar(
      periodo: f.periodo,
      tipo: f.tipo,
      categoriaId: f.categoriaId,
    );
    final dir = await getTemporaryDirectory();
    final arquivo = File(
      p.join(dir.path, '${f.nomeArquivo}.${formato.name}'),
    );
    final bytes = switch (formato) {
      FormatoPlanilha.xlsx => montarXlsx(f, itens),
      FormatoPlanilha.csv => utf8.encode(montarCsv(itens)),
    };
    return arquivo.writeAsBytes(bytes, flush: true);
  }

  /// Valores com sinal: receitas positivas, despesas negativas (soma = saldo).
  static double _valorAssinado(Lancamento l) =>
      (l.tipo == Tipo.receita ? l.valorCentavos : -l.valorCentavos) / 100;

  static List<int> montarXlsx(FiltroRelatorio f, List<Lancamento> itens) {
    final excel = Excel.createExcel();
    const aba = 'Lançamentos';
    excel.rename(excel.getDefaultSheet()!, aba);
    final sheet = excel[aba];

    sheet.appendRow([TextCellValue('Relatório NoBolso')]);
    sheet.appendRow([
      TextCellValue('Período'),
      TextCellValue(f.descricaoPeriodo),
    ]);
    sheet.appendRow([
      TextCellValue('Categoria'),
      TextCellValue(f.descricaoCategoria),
    ]);
    sheet.appendRow([TextCellValue('Tipo'), TextCellValue(f.descricaoTipo)]);
    sheet.appendRow([]);
    sheet.appendRow(cabecalho.map(TextCellValue.new).toList());
    for (final l in itens) {
      sheet.appendRow([
        DateCellValue(year: l.data.year, month: l.data.month, day: l.data.day),
        TextCellValue(l.descricao),
        TextCellValue(l.categoriaNome ?? ''),
        TextCellValue(l.tipo.rotulo),
        DoubleCellValue(_valorAssinado(l)),
      ]);
    }
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 14);
    return excel.save()!;
  }

  static String montarCsv(List<Lancamento> itens) {
    final b = StringBuffer('﻿'); // BOM: o Excel reconhece UTF-8 e os acentos.
    b.writeln(cabecalho.join(';'));
    for (final l in itens) {
      final valor = Formatadores.numero(
        l.tipo == Tipo.receita ? l.valorCentavos : -l.valorCentavos,
      ).replaceAll('.', ''); // sem separador de milhar: 1234,56
      b.writeln(
        [
          Formatadores.dataCurta(l.data),
          _escapar(l.descricao),
          _escapar(l.categoriaNome ?? ''),
          l.tipo.rotulo,
          valor,
        ].join(';'),
      );
    }
    return b.toString();
  }

  static String _escapar(String s) =>
      s.contains(RegExp(r'[;"\n\r]')) ? '"${s.replaceAll('"', '""')}"' : s;
}
