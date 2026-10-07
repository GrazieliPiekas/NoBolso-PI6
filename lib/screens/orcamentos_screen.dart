import 'package:flutter/material.dart';

import '../painters/medidor_painter.dart';
import '../services/orcamento_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_animado.dart';
import 'orcamento_form_sheet.dart';

/// Orçamentos do mês: medidor geral, avisos e limites por categoria (RF03/RF04).
class OrcamentosScreen extends StatefulWidget {
  const OrcamentosScreen({super.key});
  @override
  State<OrcamentosScreen> createState() => _OrcamentosScreenState();
}

class _OrcamentosScreenState extends State<OrcamentosScreen> {
  final _servico = OrcamentoService();
  ResumoOrcamentos? _resumo;
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
    final r = await _servico.resumo(DateTime.now());
    if (mounted) {
      setState(() {
        _resumo = r;
        _versao++;
      });
    }
  }

  void _abrirForm([StatusOrcamento? s]) =>
      OrcamentoFormSheet.abrir(context, editar: s?.orcamento);

  @override
  Widget build(BuildContext context) {
    final r = _resumo;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CabecalhoTela(
          titulo: 'Orçamentos',
          subtitulo: Formatadores.mesAno(DateTime.now()),
          acao: IconButton(
            tooltip: 'Novo orçamento',
            onPressed: _abrirForm,
            icon: const Icon(Icons.add_circle_outline, color: Cores.verde),
          ),
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Carregando()
        else if (r.vazio)
          CartaoSecao(
            child: EstadoVazio(
              icone: Icons.savings_outlined,
              titulo: 'Nenhum orçamento ainda',
              mensagem:
                  'Defina quanto quer gastar no mês, no total ou por categoria. '
                  'O NoBolso avisa com calma quando chegar a 50%, 80% e 100%.',
              acao: FilledButton.icon(
                onPressed: _abrirForm,
                icon: const Icon(Icons.add),
                label: const Text('Criar orçamento'),
              ),
            ),
          )
        else ...[
          _cartaoMedidor(r),
          ..._avisos(r),
          _cartaoCategorias(r),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _cartaoMedidor(ResumoOrcamentos r) {
    final p = r.percentualMedidor;
    return GestureDetector(
      onTap: () => _abrirForm(r.geral),
      child: CartaoSecao(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, c) => GraficoAnimado(
                chave: _versao,
                altura: c.maxWidth * 0.5,
                descricaoAcessivel:
                    'Medidor: ${(p * 100).round()}% do orçamento usado',
                painter: (t) => MedidorPainter(p, progresso: t),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(p * 100).round()}%',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Cores.texto,
              ),
            ),
            Text(
              r.medidorPelaSoma
                  ? 'da soma dos limites por categoria'
                  : 'do orçamento usado',
              style: const TextStyle(color: Cores.textoSuave),
            ),
            const SizedBox(height: 10),
            Text(
              '${Formatadores.moeda(r.usadoMedidor)} de ${Formatadores.moeda(r.limiteMedidor)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: MedidorPainter.corDaFaixa(p),
              ),
            ),
            if (r.geral == null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => OrcamentoFormSheet.abrir(context, geral: true),
                icon: const Icon(Icons.add),
                label: const Text('Definir orçamento geral do mês'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _avisos(ResumoOrcamentos r) => [
    for (final s in [?r.geral, ...r.categorias])
      if (s.percentual >= 0.8)
        Aviso(
          titulo: s.percentual >= 1
              ? '${s.orcamento.nome} chegou ao limite'
              : '${s.orcamento.nome} chegou a ${(s.percentual * 100).round()}% do limite',
          mensagem: s.disponivel >= 0
              ? 'Restam ${Formatadores.moeda(s.disponivel)} até o fim do mês'
              : 'Passou ${Formatadores.moeda(-s.disponivel)} do planejado. Você pode ajustar o limite quando quiser.',
        ),
    if (r.somaExcedeGeral)
      Aviso(
        alerta: false,
        titulo: 'Os limites por categoria somam mais que o geral',
        mensagem:
            'Soma: ${Formatadores.moeda(r.somaLimitesCategorias)}; geral: ${Formatadores.moeda(r.geral!.limite)}. Só um lembrete.',
      ),
  ];

  Widget _cartaoCategorias(ResumoOrcamentos r) => CartaoSecao(
    titulo: 'Limites por categoria',
    acao: TextButton(
      onPressed: _abrirForm,
      child: const Text('Adicionar', style: TextStyle(color: Cores.textoSuave)),
    ),
    child: r.categorias.isEmpty
        ? const Text(
            'Nenhum limite por categoria. Toque em "Adicionar" para criar um.',
            style: TextStyle(color: Cores.textoSuave),
          )
        : Column(
            children: [
              for (final s in r.categorias)
                InkWell(
                  onTap: () => _abrirForm(s),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.orcamento.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '${Formatadores.moedaCurta(s.usado)} / ${Formatadores.moedaCurta(s.limite).replaceFirst(r'R$ ', '')}',
                              style: const TextStyle(color: Cores.textoSuave),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BarraProgresso(
                          fracao: s.percentual,
                          cor: s.percentual >= 1
                              ? Cores.despesa
                              : s.orcamento.cor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}
