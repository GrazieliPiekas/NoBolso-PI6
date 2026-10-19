import 'package:flutter/material.dart';

import '../painters/medidor_painter.dart';
import '../services/orcamento_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../viewmodels/orcamentos_view_model.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_animado.dart';
import 'orcamento_form_sheet.dart';

/// Orçamentos do mês: medidor geral, avisos e limites por categoria (RF03/RF04).
class OrcamentosView extends StatefulWidget {
  const OrcamentosView({super.key});
  @override
  State<OrcamentosView> createState() => _OrcamentosViewState();
}

class _OrcamentosViewState extends State<OrcamentosView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = OrcamentosViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  int get _versao => _viewModel.versao;

  void _abrirForm([StatusOrcamento? status]) =>
      OrcamentoFormSheet.abrir(context, editar: status?.orcamento);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() {
    final resumo = _viewModel.resumo;
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
        if (resumo == null)
          const Carregando()
        else if (resumo.vazio)
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
          _cartaoMedidor(resumo),
          ..._avisos(resumo),
          _cartaoCategorias(resumo),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _cartaoMedidor(ResumoOrcamentos resumo) {
    final percentual = resumo.percentualMedidor;
    return GestureDetector(
      onTap: () => _abrirForm(resumo.geral),
      child: CartaoSecao(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, limites) => GraficoAnimado(
                chave: _versao,
                altura: limites.maxWidth * 0.5,
                descricaoAcessivel:
                    'Medidor: ${(percentual * 100).round()}% do orçamento usado',
                painter: (progresso) =>
                    MedidorPainter(percentual, progresso: progresso),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(percentual * 100).round()}%',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Cores.texto,
              ),
            ),
            Text(
              resumo.medidorPelaSoma
                  ? 'da soma dos limites por categoria'
                  : 'do orçamento usado',
              style: const TextStyle(color: Cores.textoSuave),
            ),
            const SizedBox(height: 10),
            Text(
              '${Formatadores.moeda(resumo.usadoMedidor)} de ${Formatadores.moeda(resumo.limiteMedidor)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: MedidorPainter.corDaFaixa(percentual),
              ),
            ),
            if (resumo.geral == null) ...[
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

  List<Widget> _avisos(ResumoOrcamentos resumo) => [
    for (final status in [?resumo.geral, ...resumo.categorias])
      if (status.percentual >= 0.8)
        Aviso(
          titulo: status.percentual >= 1
              ? '${status.orcamento.nome} chegou ao limite'
              : '${status.orcamento.nome} chegou a ${(status.percentual * 100).round()}% do limite',
          mensagem: status.disponivel >= 0
              ? 'Restam ${Formatadores.moeda(status.disponivel)} até o fim do mês'
              : 'Passou ${Formatadores.moeda(-status.disponivel)} do planejado. Você pode ajustar o limite quando quiser.',
        ),
    if (resumo.somaExcedeGeral)
      Aviso(
        alerta: false,
        titulo: 'Os limites por categoria somam mais que o geral',
        mensagem:
            'Soma: ${Formatadores.moeda(resumo.somaLimitesCategorias)}; geral: ${Formatadores.moeda(resumo.geral!.limite)}. Só um lembrete.',
      ),
  ];

  Widget _cartaoCategorias(ResumoOrcamentos resumo) => CartaoSecao(
    titulo: 'Limites por categoria',
    acao: TextButton(
      onPressed: _abrirForm,
      child: const Text('Adicionar', style: TextStyle(color: Cores.textoSuave)),
    ),
    child: resumo.categorias.isEmpty
        ? const Text(
            'Nenhum limite por categoria. Toque em "Adicionar" para criar um.',
            style: TextStyle(color: Cores.textoSuave),
          )
        : Column(
            children: [
              for (final status in resumo.categorias)
                InkWell(
                  onTap: () => _abrirForm(status),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                status.orcamento.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '${Formatadores.moedaCurta(status.usado)} / ${Formatadores.moedaCurta(status.limite).replaceFirst(r'R$ ', '')}',
                              style: const TextStyle(color: Cores.textoSuave),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BarraProgresso(
                          fracao: status.percentual,
                          cor: status.percentual >= 1
                              ? Cores.despesa
                              : status.orcamento.cor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}
