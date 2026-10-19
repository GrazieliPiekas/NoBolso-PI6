import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/categoria.dart';
import '../models/tipo.dart';
import '../services/recomendacao_service.dart';
import '../services/relatorio_planilha_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../viewmodels/relatorios_view_model.dart';
import '../widgets/componentes.dart';

/// Relatórios: filtros De/Até, categoria e tipo; resumo; exportar PDF / XLSX / CSV;
/// recomendações automáticas.
class RelatoriosView extends StatefulWidget {
  const RelatoriosView({super.key});
  @override
  State<RelatoriosView> createState() => _RelatoriosViewState();
}

class _RelatoriosViewState extends State<RelatoriosView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = RelatoriosViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _escolherData({required bool inicio}) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: inicio ? _viewModel.periodo.de : _viewModel.periodo.ate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dataEscolhida == null) return;
    inicio
        ? _viewModel.definirInicio(dataEscolhida)
        : _viewModel.definirFim(dataEscolhida);
  }

  Future<void> _exportar(Future<void> Function() exportar, String nome) async {
    try {
      await exportar();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar o $nome: $erro')),
        );
      }
    }
  }

  void _exportarPdf() => _exportar(_viewModel.exportarPdf, 'PDF');

  Future<void> _exportarPlanilha() async {
    final formato = await showModalBottomSheet<FormatoPlanilha>(
      context: context,
      builder: (contextoDialogo) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grid_on, color: Cores.verde),
              title: const Text('Excel (.xlsx)'),
              onTap: () => Navigator.pop(contextoDialogo, FormatoPlanilha.xlsx),
            ),
            ListTile(
              leading: const Icon(
                Icons.text_snippet_outlined,
                color: Cores.verde,
              ),
              title: const Text('CSV (.csv)'),
              subtitle: const Text('Separado por ponto e vírgula'),
              onTap: () => Navigator.pop(contextoDialogo, FormatoPlanilha.csv),
            ),
          ],
        ),
      ),
    );
    if (formato == null) return;
    _exportar(() => _viewModel.exportarPlanilha(formato), 'arquivo');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() => Stack(
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
      if (_viewModel.exportando)
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
            _caixaData(
              'De',
              _viewModel.periodo.de,
              () => _escolherData(inicio: true),
            ),
            const SizedBox(width: 10),
            _caixaData(
              'Até',
              _viewModel.periodo.ate,
              () => _escolherData(inicio: false),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<Categoria?>(
                onSelected: _viewModel.mudarCategoria,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  for (final categoria in _viewModel.categoriasDoTipo)
                    PopupMenuItem(
                      value: categoria,
                      child: Text(
                        _viewModel.tipo == null
                            ? '${categoria.nome} (${categoria.tipo.rotulo.toLowerCase()})'
                            : categoria.nome,
                      ),
                    ),
                ],
                child: _pilulaFiltro(_viewModel.filtro.descricaoCategoria),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PopupMenuButton<Tipo?>(
                onSelected: _viewModel.mudarTipo,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Receitas e despesas'),
                  ),
                  for (final tipo in Tipo.values)
                    PopupMenuItem(value: tipo, child: Text(tipo.rotuloPlural)),
                ],
                child: _pilulaFiltro(_viewModel.filtro.descricaoTipo),
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
    final totais = _viewModel.totais;
    if (totais == null) return const CartaoSecao(child: Carregando());
    final maior = math.max(1, math.max(totais.receitas, totais.despesas));
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
        '${totais.quantidade} lançamento${totais.quantidade == 1 ? '' : 's'}',
      ),
      child: Column(
        children: [
          linha('Receitas', totais.receitas, Cores.verde),
          linha('Despesas', totais.despesas, Cores.despesa),
          linha(
            'Saldo',
            totais.saldo,
            totais.saldo >= 0 ? Cores.verde : Cores.despesa,
          ),
        ],
      ),
    );
  }

  Widget _botoesExportar() {
    final semDados = _viewModel.semDados;
    Widget botao(
      String sigla,
      String rotulo,
      Color cor,
      Color fundo,
      VoidCallback aoTocar,
    ) => Expanded(
      child: Material(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: semDados || _viewModel.exportando
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Não há lançamentos com esses filtros para exportar.',
                    ),
                  ),
                )
              : aoTocar,
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
                    style: TextStyle(color: cor, fontWeight: FontWeight.w800),
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
    final recomendacoes = _viewModel.recomendacoes;
    return CartaoSecao(
      titulo: 'Recomendações',
      acao: const RotuloSuave('Automáticas'),
      child: recomendacoes == null
          ? const Carregando()
          : Column(
              children: [
                for (final item in recomendacoes) _ItemRecomendacao(item),
              ],
            ),
    );
  }
}

class _ItemRecomendacao extends StatelessWidget {
  final Recomendacao recomendacao;
  const _ItemRecomendacao(this.recomendacao);

  @override
  Widget build(BuildContext context) {
    final (fundo, cor) = switch (recomendacao.tipo) {
      TipoRecomendacao.alerta => (const Color(0xFFF5EADC), Cores.alerta),
      TipoRecomendacao.dica => (
        const Color(0xFFEDEAE0),
        const Color(0xFF5A7A8A),
      ),
      TipoRecomendacao.info => (
        const Color(0xFFECEAE3),
        const Color(0xFF8A7088),
      ),
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
                  recomendacao.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  recomendacao.descricao,
                  style: const TextStyle(
                    color: Cores.textoSuave,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
