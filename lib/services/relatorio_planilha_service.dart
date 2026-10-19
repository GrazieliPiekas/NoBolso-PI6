import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as caminho;
import 'package:path_provider/path_provider.dart';

import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../utils/formatadores.dart';
import 'filtro_relatorio.dart';

/// Formatos de planilha que o usuário pode escolher.
enum FormatoPlanilha { xlsx, csv }

/// Exportação em .xlsx e .csv (decisão 8). O CSV usa `;` e vírgula decimal
/// para abrir direto no Excel em português.
class RelatorioPlanilhaService {
  final LancamentoDao _dao;
  RelatorioPlanilhaService([LancamentoDao? dao])
    : _dao = dao ?? LancamentoDao();

  static const cabecalho = [
    'Data',
    'Descrição',
    'Categoria',
    'Tipo',
    'Valor (R\$)',
  ];

  /// Gera o arquivo no formato escolhido e salva numa pasta temporária.
  Future<File> gerar(FiltroRelatorio filtro, FormatoPlanilha formato) async {
    final itens = await _dao.listar(
      periodo: filtro.periodo,
      tipo: filtro.tipo,
      categoriaId: filtro.categoriaId,
    );
    final dir = await getTemporaryDirectory();
    final arquivo = File(
      caminho.join(dir.path, '${filtro.nomeArquivo}.${formato.name}'),
    );
    final bytes = switch (formato) {
      FormatoPlanilha.xlsx => montarXlsx(filtro, itens),
      FormatoPlanilha.csv => utf8.encode(montarCsv(itens)),
    };
    return arquivo.writeAsBytes(bytes, flush: true);
  }

  /// Valores com sinal: receitas positivas, despesas negativas (soma = saldo).
  static double _valorAssinado(Lancamento lancamento) =>
      (lancamento.tipo == Tipo.receita
          ? lancamento.valorCentavos
          : -lancamento.valorCentavos) /
      100;

  /// Monta o .xlsx: cabeçalho com os filtros e uma linha por lançamento.
  static List<int> montarXlsx(FiltroRelatorio filtro, List<Lancamento> itens) {
    final excel = Excel.createExcel();
    const aba = 'Lançamentos';
    excel.rename(excel.getDefaultSheet()!, aba);
    final sheet = excel[aba];

    sheet.appendRow([TextCellValue('Relatório NoBolso')]);
    sheet.appendRow([
      TextCellValue('Período'),
      TextCellValue(filtro.descricaoPeriodo),
    ]);
    sheet.appendRow([
      TextCellValue('Categoria'),
      TextCellValue(filtro.descricaoCategoria),
    ]);
    sheet.appendRow([
      TextCellValue('Tipo'),
      TextCellValue(filtro.descricaoTipo),
    ]);
    sheet.appendRow([]);
    sheet.appendRow(cabecalho.map(TextCellValue.new).toList());
    for (final lancamento in itens) {
      sheet.appendRow([
        DateCellValue(
          year: lancamento.data.year,
          month: lancamento.data.month,
          day: lancamento.data.day,
        ),
        TextCellValue(lancamento.descricao),
        TextCellValue(lancamento.categoriaNome ?? ''),
        TextCellValue(lancamento.tipo.rotulo),
        DoubleCellValue(_valorAssinado(lancamento)),
      ]);
    }
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 14);
    return excel.save()!;
  }

  /// Monta o CSV com ; e vírgula decimal, que é o que o Excel em português espera.
  static String montarCsv(List<Lancamento> itens) {
    // Começa com o BOM (caractere invisível) para o Excel reconhecer UTF-8
    // e mostrar os acentos certinho.
    final conteudo = StringBuffer('﻿');
    conteudo.writeln(cabecalho.join(';'));
    for (final lancamento in itens) {
      final valor = Formatadores.numero(
        lancamento.tipo == Tipo.receita
            ? lancamento.valorCentavos
            : -lancamento.valorCentavos,
      ).replaceAll('.', ''); // sem separador de milhar: 1234,56
      conteudo.writeln(
        [
          Formatadores.dataCurta(lancamento.data),
          _escapar(lancamento.descricao),
          _escapar(lancamento.categoriaNome ?? ''),
          lancamento.tipo.rotulo,
          valor,
        ].join(';'),
      );
    }
    return conteudo.toString();
  }

  // Se o texto tiver ; aspas ou quebra de linha, coloca entre aspas
  // (e dobra as aspas de dentro), senão o Excel quebra a coluna.
  static String _escapar(String texto) {
    if (!texto.contains(RegExp(r'[;"\n\r]'))) return texto;
    final aspasDobradas = texto.replaceAll('"', '""');
    return '"$aspasDobradas"';
  }
}
