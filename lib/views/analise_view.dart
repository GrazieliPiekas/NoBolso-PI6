import 'package:flutter/material.dart';

import '../painters/linha_painter.dart';
import '../painters/mapa_calor_painter.dart';
import '../services/dados_graficos_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../viewmodels/analise_view_model.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_animado.dart';

/// Análise: filtro Mês/Trimestre/Ano, linha (evolução do saldo), mapa de calor e destaque.
class AnaliseView extends StatefulWidget {
  const AnaliseView({super.key});
  @override
  State<AnaliseView> createState() => _AnaliseViewState();
}

class _AnaliseViewState extends State<AnaliseView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = AnaliseViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  FiltroAnalise get _filtro => _viewModel.filtro;
  int get _versao => _viewModel.versao;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() {
    final dados = _viewModel.dados;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const CabecalhoTela(
          titulo: 'Análise',
          subtitulo: 'Como seu dinheiro se comporta',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              for (final opcao in FiltroAnalise.values)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(opcao.rotulo),
                    selected: opcao == _filtro,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.fonte,
                      color: opcao == _filtro ? Colors.white : Cores.textoSuave,
                      fontWeight: opcao == _filtro
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => _viewModel.mudarFiltro(opcao),
                  ),
                ),
            ],
          ),
        ),
        if (dados == null)
          const Carregando()
        else if (dados.totais.quantidade == 0)
          const CartaoSecao(
            child: EstadoVazio(
              icone: Icons.insights_outlined,
              titulo: 'Sem lançamentos neste período',
              mensagem:
                  'Registre receitas e despesas para ver a evolução do saldo '
                  'e em quais dias você mais gasta.',
            ),
          )
        else ...[
          CartaoSecao(
            titulo: 'Evolução do saldo',
            acao: RotuloSuave(Formatadores.moeda(dados.totais.saldo)),
            child: GraficoAnimado(
              chave: _versao,
              altura: 220,
              descricaoAcessivel:
                  'Gráfico de linha do saldo acumulado; saldo final ${Formatadores.moeda(dados.totais.saldo)}',
              painter: (progresso) =>
                  LinhaPainter(dados.saldo, progresso: progresso),
            ),
          ),
          CartaoSecao(
            titulo: 'Concentração de gastos',
            acao: const RotuloSuave('Por dia da semana'),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, limites) => GraficoAnimado(
                    chave: _versao,
                    altura: MapaCalorPainter.alturaPara(
                      limites.maxWidth,
                      dados.calor.valores.length,
                    ),
                    descricaoAcessivel: dados.destaque == null
                        ? 'Mapa de calor de gastos por dia da semana'
                        : 'Mapa de calor: ${dados.destaque!.nome} é o dia com mais gastos',
                    painter: (progresso) =>
                        MapaCalorPainter(dados.calor, progresso: progresso),
                  ),
                ),
                const SizedBox(height: 12),
                const _LegendaCalor(),
              ],
            ),
          ),
          if (dados.destaque != null)
            Aviso(
              alerta: false,
              titulo:
                  '${dados.destaque!.nome} concentra ${(dados.destaque!.fracao * 100).round()}% dos gastos',
              mensagem: dados.maiorCategoria == null
                  ? null
                  : 'Maior categoria no período: ${dados.maiorCategoria}',
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LegendaCalor extends StatelessWidget {
  const _LegendaCalor();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Menos',
        style: TextStyle(color: Cores.textoSuave, fontSize: 12),
      ),
      const SizedBox(width: 8),
      for (final intensidade in const [0.0, 0.25, 0.5, 0.75, 1.0])
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: MapaCalorPainter.corPara(intensidade),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      const SizedBox(width: 8),
      const Text(
        'Mais gastos',
        style: TextStyle(color: Cores.textoSuave, fontSize: 12),
      ),
    ],
  );
}
