import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../utils/formatadores.dart';
import 'filtro_relatorio.dart';

/// PDF com cabeçalho dos filtros, resumo e tabela de lançamentos (decisão 9: sem gráficos).
class RelatorioPdfService {
  final LancamentoDao _dao;
  RelatorioPdfService([LancamentoDao? dao]) : _dao = dao ?? LancamentoDao();

  static const _verde = PdfColor.fromInt(0xFF3E6A46);
  static const _vermelho = PdfColor.fromInt(0xFFB85C41);
  static const _cinza = PdfColor.fromInt(0xFF8A8778);
  static const _bege = PdfColor.fromInt(0xFFEFE5DA);

  Future<File> gerar(FiltroRelatorio f) async {
    final itens = await _dao.listar(
      periodo: f.periodo,
      tipo: f.tipo,
      categoriaId: f.categoriaId,
    );
    final totais = await _dao.totais(
      periodo: f.periodo,
      tipo: f.tipo,
      categoriaId: f.categoriaId,
    );
    final tema = pw.ThemeData.withFont(
      base: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf')),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf')),
    );
    final bytes = await montar(f, itens, totais, tema: tema);
    final dir = await getTemporaryDirectory();
    final arquivo = File(p.join(dir.path, '${f.nomeArquivo}.pdf'));
    return arquivo.writeAsBytes(bytes, flush: true);
  }

  /// Separado de [gerar] para poder ser testado sem sistema de arquivos.
  static Future<Uint8List> montar(
    FiltroRelatorio f,
    List<Lancamento> itens,
    Totais totais, {
    DateTime? geradoEm,
    pw.ThemeData? tema,
  }) {
    final doc = pw.Document(
      title: 'Relatório NoBolso',
      author: 'NoBolso',
      theme: tema,
    );
    final quando = geradoEm ?? DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text(
                'NoBolso · ${f.descricaoPeriodo}',
                style: const pw.TextStyle(color: _cinza, fontSize: 9),
              ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Gerado no aparelho em ${Formatadores.dataCurta(quando)}. Dados 100% locais.',
              style: const pw.TextStyle(color: _cinza, fontSize: 8),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(color: _cinza, fontSize: 8),
            ),
          ],
        ),
        build: (ctx) => [
          pw.Text(
            'Relatório financeiro',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _verde,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Período: ${f.descricaoPeriodo}'),
          pw.Text('Categoria: ${f.descricaoCategoria}'),
          pw.Text('Tipo: ${f.descricaoTipo}'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _bege,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _resumo('Receitas', totais.receitas, _verde),
                _resumo('Despesas', totais.despesas, _vermelho),
                _resumo(
                  'Saldo',
                  totais.saldo,
                  totais.saldo >= 0 ? _verde : _vermelho,
                ),
                _resumoTexto('Lançamentos', '${totais.quantidade}'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          if (itens.isEmpty)
            pw.Text(
              'Nenhum lançamento encontrado com esses filtros.',
              style: const pw.TextStyle(color: _cinza),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Descrição', 'Categoria', 'Tipo', 'Valor'],
              data: [
                for (final l in itens)
                  [
                    Formatadores.dataCurta(l.data),
                    l.descricao,
                    l.categoriaNome ?? '',
                    l.tipo.rotulo,
                    Formatadores.moedaComSinal(
                      l.valorCentavos,
                      positivo: l.tipo == Tipo.receita,
                    ),
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: _verde),
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration: const pw.BoxDecoration(color: _bege),
              cellAlignments: {4: pw.Alignment.centerRight},
              columnWidths: {
                0: const pw.FixedColumnWidth(62),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(55),
                4: const pw.FixedColumnWidth(85),
              },
            ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _resumo(String rotulo, int centavos, PdfColor cor) =>
      _resumoTexto(rotulo, Formatadores.moeda(centavos), cor: cor);

  static pw.Widget _resumoTexto(
    String rotulo,
    String valor, {
    PdfColor cor = PdfColors.black,
  }) => pw.Column(
    children: [
      pw.Text(rotulo, style: const pw.TextStyle(color: _cinza, fontSize: 9)),
      pw.SizedBox(height: 2),
      pw.Text(
        valor,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: cor),
      ),
    ],
  );
}
