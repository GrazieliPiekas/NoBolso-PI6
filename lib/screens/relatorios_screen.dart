import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../services/filtro_relatorio.dart';
import '../services/recomendacao_service.dart';
import '../services/relatorio_pdf_service.dart';
import '../services/relatorio_planilha_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../widgets/componentes.dart';

/// Relatórios: filtros De/Até, categoria e tipo; resumo; exportar PDF / XLSX / CSV;
/// recomendações automáticas.
class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});
  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final _dao = LancamentoDao();
  Periodo _periodo = Periodo.mes(DateTime.now());
  Tipo? _tipo;
  Categoria? _categoria;
  List<Categoria> _categorias = [];
  Totais? _totais;
  List<Recomendacao>? _recomendacoes;
  bool _exportando = false;

  FiltroRelatorio get _filtro => FiltroRelatorio(
    periodo: _periodo,
    tipo: _tipo,
    categoriaId: _categoria?.id,
    categoriaNome: _categoria?.nome,
  );

  @override
  void initState() {
    super.initState();
    Eventos.dadosAlterados.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    final cats = await CategoriaDao().listar();
    final t = await _dao.totais(
      periodo: _periodo,
      tipo: _tipo,
      categoriaId: _categoria?.id,
    );
    final rec = await RecomendacaoService().gerar(_periodo);
    if (!mounted) return;
    setState(() {
      _categorias = cats;
      // A categoria pode ter sido excluída/alterada em outra tela.
      if (_categoria != null && !cats.any((c) => c.id == _categoria!.id)) {
        _categoria = null;
      }
      _totais = t;
      _recomendacoes = rec;
    });
  }

  Future<void> _escolherData({required bool inicio}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? _periodo.de : _periodo.ate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (inicio) {
        _periodo = Periodo(d, d.isAfter(_periodo.ate) ? d : _periodo.ate);
      } else {
        _periodo = Periodo(d.isBefore(_periodo.de) ? d : _periodo.de, d);
      }
    });
    _carregar();
  }

  Future<void> _exportar(Future<File> Function() gerar, String nome) async {
    setState(() => _exportando = true);
    try {
      final arquivo = await gerar();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(arquivo.path)],
          subject: 'Relatório NoBolso',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar o $nome: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _exportarPdf() =>
      _exportar(() => RelatorioPdfService().gerar(_filtro), 'PDF');

  Future<void> _exportarPlanilha() async {
    final formato = await showModalBottomSheet<FormatoPlanilha>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grid_on, color: Cores.verde),
              title: const Text('Excel (.xlsx)'),
              onTap: () => Navigator.pop(c, FormatoPlanilha.xlsx),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined, color: Cores.verde),
              title: const Text('CSV (.csv)'),
              subtitle: const Text('Separado por ponto e vírgula'),
              onTap: () => Navigator.pop(c, FormatoPlanilha.csv),
            ),
          ],
        ),
      ),
    );
    if (formato == null) return;
    _exportar(
      () => RelatorioPlanilhaService().gerar(_filtro, formato),
      'arquivo',
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ListView(
        padding: EdgeInsets.zero,
        children: [
          const CabecalhoTela(
            titulo: 'Relatórios',
            subtitulo: 'Exporte e revise seus dados',
          ),
          const SizedBox(height: 16),
          _cartaoFiltros(),
          _cartaoResumo(),
          _botoesExportar(),
          _cartaoRecomendacoes(),
          const SizedBox(height: 12),
        ],
      ),
      if (_exportando)
        const ColoredBox(
          color: Color(0x55000000),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
    ],
  );

  Widget _cartaoFiltros() => CartaoSecao(
    titulo: 'Período do relatório',
    child: Column(
      children: [
        Row(
          children: [
            _caixaData('De', _periodo.de, () => _escolherData(inicio: true)),
            const SizedBox(width: 10),
            _caixaData('Até', _periodo.ate, () => _escolherData(inicio: false)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<Categoria?>(
                onSelected: (c) {
                  setState(() => _categoria = c);
                  _carregar();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  for (final c in _categorias.where(
                    (c) => _tipo == null || c.tipo == _tipo,
                  ))
                    PopupMenuItem(
                      value: c,
                      child: Text(
                        _tipo == null
                            ? '${c.nome} (${c.tipo.rotulo.toLowerCase()})'
                            : c.nome,
                      ),
                    ),
                ],
                child: _pilulaFiltro(_filtro.descricaoCategoria),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PopupMenuButton<Tipo?>(
                onSelected: (t) {
                  setState(() {
                    _tipo = t;
                    if (_categoria != null && t != null && _categoria!.tipo != t) {
                      _categoria = null;
                    }
                  });
                  _carregar();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Receitas e despesas'),
                  ),
                  for (final t in Tipo.values)
                    PopupMenuItem(value: t, child: Text(t.rotuloPlural)),
                ],
                child: _pilulaFiltro(_filtro.descricaoTipo),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _caixaData(String rotulo, DateTime data, VoidCallback onTap) =>
      Expanded(
        child: Material(
          color: Cores.campo,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: const TextStyle(
                      color: Cores.textoSuave,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    Formatadores.dataCurta(data),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _pilulaFiltro(String texto) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE7E7DE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Cores.verde,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const Icon(Icons.arrow_drop_down, color: Cores.verde, size: 20),
      ],
    ),
  );

  Widget _cartaoResumo() {
    final t = _totais;
    if (t == null) return const CartaoSecao(child: Carregando());
    final maior = math.max(1, math.max(t.receitas, t.despesas));
    Widget linha(String rotulo, int valor, Color cor) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rotulo,
                  style: const TextStyle(color: Cores.textoSuave),
                ),
              ),
              Text(
                Formatadores.moeda(valor),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BarraProgresso(fracao: valor.abs() / maior, cor: cor, altura: 8),
        ],
      ),
    );
    return CartaoSecao(
      titulo: 'Resumo do período',
      acao: RotuloSuave(
        '${t.quantidade} lançamento${t.quantidade == 1 ? '' : 's'}',
      ),
      child: Column(
        children: [
          linha('Receitas', t.receitas, Cores.verde),
          linha('Despesas', t.despesas, Cores.despesa),
          linha('Saldo', t.saldo, t.saldo >= 0 ? Cores.verde : Cores.despesa),
        ],
      ),
    );
  }

  Widget _botoesExportar() {
    final semDados = (_totais?.quantidade ?? 0) == 0;
    Widget botao(String sigla, String rotulo, Color cor, Color fundo, VoidCallback f) =>
        Expanded(
          child: Material(
            color: Cores.cartao,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: semDados || _exportando
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não há lançamentos com esses filtros para exportar.'),
                      ),
                    )
                  : f,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fundo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sigla,
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rotulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          botao(
            'PDF',
            'Exportar PDF',
            Cores.despesa,
            const Color(0xFFF2DED6),
            _exportarPdf,
          ),
          const SizedBox(width: 12),
          botao(
            'XLS',
            'Exportar planilha',
            Cores.verde,
            const Color(0xFFE1E3D9),
            _exportarPlanilha,
          ),
        ],
      ),
    );
  }

  Widget _cartaoRecomendacoes() {
    final r = _recomendacoes;
    return CartaoSecao(
      titulo: 'Recomendações',
      acao: const RotuloSuave('Automáticas'),
      child: r == null
          ? const Carregando()
          : Column(children: [for (final x in r) _ItemRecomendacao(x)]),
    );
  }
}

class _ItemRecomendacao extends StatelessWidget {
  final Recomendacao r;
  const _ItemRecomendacao(this.r);

  @override
  Widget build(BuildContext context) {
    final (fundo, cor) = switch (r.tipo) {
      TipoRecomendacao.alerta => (const Color(0xFFF5EADC), Cores.alerta),
      TipoRecomendacao.dica => (const Color(0xFFEDEAE0), const Color(0xFF5A7A8A)),
      TipoRecomendacao.info => (const Color(0xFFECEAE3), const Color(0xFF8A7088)),
      TipoRecomendacao.positivo => (const Color(0xFFE8EBE0), Cores.verde),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cor.withValues(alpha: 0.2),
            child: Bolinha(cor, tamanho: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  r.descricao,
                  style: const TextStyle(color: Cores.textoSuave, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
