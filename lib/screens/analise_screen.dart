import 'package:flutter/material.dart';

import '../painters/linha_painter.dart';
import '../painters/mapa_calor_painter.dart';
import '../services/dados_graficos_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_animado.dart';

/// Análise: filtro Mês/Trimestre/Ano, linha (evolução do saldo), mapa de calor e destaque.
class AnaliseScreen extends StatefulWidget {
  const AnaliseScreen({super.key});
  @override
  State<AnaliseScreen> createState() => _AnaliseScreenState();
}

class _AnaliseScreenState extends State<AnaliseScreen> {
  final _servico = DadosGraficosService();
  FiltroAnalise _filtro = FiltroAnalise.mes;
  DadosAnalise? _dados;
  int _versao = 0;

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
    final d = await _servico.analise(_filtro);
    if (mounted) {
      setState(() {
        _dados = d;
        _versao++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _dados;
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
              for (final f in FiltroAnalise.values)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(f.rotulo),
                    selected: f == _filtro,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.fonte,
                      color: f == _filtro ? Colors.white : Cores.textoSuave,
                      fontWeight: f == _filtro
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) {
                      setState(() => _filtro = f);
                      _carregar();
                    },
                  ),
                ),
            ],
          ),
        ),
        if (d == null)
          const Carregando()
        else if (d.totais.quantidade == 0)
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
            acao: RotuloSuave(Formatadores.moeda(d.totais.saldo)),
            child: GraficoAnimado(
              chave: _versao,
              altura: 220,
              descricaoAcessivel:
                  'Gráfico de linha do saldo acumulado; saldo final ${Formatadores.moeda(d.totais.saldo)}',
              painter: (p) => LinhaPainter(d.saldo, progresso: p),
            ),
          ),
          CartaoSecao(
            titulo: 'Concentração de gastos',
            acao: const RotuloSuave('Por dia da semana'),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, c) => GraficoAnimado(
                    chave: _versao,
                    altura: MapaCalorPainter.alturaPara(
                      c.maxWidth,
                      d.calor.valores.length,
                    ),
                    descricaoAcessivel: d.destaque == null
                        ? 'Mapa de calor de gastos por dia da semana'
                        : 'Mapa de calor: ${d.destaque!.nome} é o dia com mais gastos',
                    painter: (p) => MapaCalorPainter(d.calor, progresso: p),
                  ),
                ),
                const SizedBox(height: 12),
                const _LegendaCalor(),
              ],
            ),
          ),
          if (d.destaque != null)
            Aviso(
              alerta: false,
              titulo:
                  '${d.destaque!.nome} concentra ${(d.destaque!.fracao * 100).round()}% dos gastos',
              mensagem: d.maiorCategoria == null
                  ? null
                  : 'Maior categoria no período: ${d.maiorCategoria}',
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
      const Text('Menos', style: TextStyle(color: Cores.textoSuave, fontSize: 12)),
      const SizedBox(width: 8),
      for (final f in const [0.0, 0.25, 0.5, 0.75, 1.0])
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: MapaCalorPainter.corPara(f),
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
