import 'package:flutter/material.dart';

import '../painters/barras_painter.dart';
import '../painters/rosca_painter.dart';
import '../services/dados_graficos_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../viewmodels/inicio_view_model.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_animado.dart';
import '../widgets/item_lancamento.dart';
import '../widgets/perfil_dialog.dart';
import 'categorias_view.dart';
import 'lancamento_form_view.dart';
import 'lancamentos_view.dart';
import 'tutorial_view.dart';

/// Painel: saldo do mês, rosca (receitas × despesas), barras (gastos por categoria)
/// e últimos lançamentos.
class InicioView extends StatefulWidget {
  const InicioView({super.key});
  @override
  State<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends State<InicioView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = InicioViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  int get _versao => _viewModel.versao;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() {
    final dados = _viewModel.dados;
    return RefreshIndicator(
      color: Cores.verde,
      onRefresh: _viewModel.carregar,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cabecalho(nome: _viewModel.nome, dados: dados),
          const SizedBox(height: 18),
          if (dados == null)
            const Carregando()
          else ...[
            _cartaoRosca(dados),
            _cartaoBarras(dados),
            _cartaoUltimos(dados),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _cartaoRosca(DadosInicio dados) {
    final totais = dados.totais;
    final total = totais.receitas + totais.despesas;
    String porcentagem(int valor) =>
        total == 0 ? '0%' : '${(valor * 100 / total).round()}%';
    return CartaoSecao(
      titulo: 'Receitas x Despesas',
      acao: RotuloSuave(Formatadores.mesAno(DateTime.now()).split(' ').first),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: GraficoAnimado(
              chave: _versao,
              altura: 150,
              descricaoAcessivel:
                  'Gráfico de rosca: receitas ${Formatadores.moeda(totais.receitas)}, '
                  'despesas ${Formatadores.moeda(totais.despesas)}',
              painter: (progresso) => RoscaPainter(
                [
                  FatiaRosca(totais.receitas.toDouble(), Cores.verde),
                  FatiaRosca(totais.despesas.toDouble(), Cores.despesaClara),
                ],
                textoCentro: Formatadores.moedaCurta(totais.saldo),
                subtextoCentro: 'saldo',
                progresso: progresso,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _legenda(Cores.verde, 'Receitas', porcentagem(totais.receitas)),
                const SizedBox(height: 10),
                _legenda(
                  Cores.despesaClara,
                  'Despesas',
                  porcentagem(totais.despesas),
                ),
                const SizedBox(height: 14),
                Text(
                  total == 0
                      ? 'Nenhum lançamento neste mês ainda.'
                      : totais.receitas == 0
                      ? 'Sem receitas registradas no mês.'
                      : 'Você gastou ${(totais.despesas * 100 / totais.receitas).round()}% do que recebeu.',
                  style: const TextStyle(color: Cores.textoSuave, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legenda(Color cor, String nome, String valor) => Row(
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(nome, style: const TextStyle(fontSize: 15))),
      Text(
        valor,
        style: const TextStyle(
          color: Cores.textoSuave,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _cartaoBarras(DadosInicio dados) => CartaoSecao(
    titulo: 'Gastos por categoria',
    acao: const RotuloSuave('Este mês'),
    child: dados.porCategoria.isEmpty
        ? const EstadoVazio(
            icone: Icons.bar_chart,
            titulo: 'Sem despesas este mês',
            mensagem: 'Quando você registrar gastos, eles aparecem aqui por categoria.',
          )
        : GraficoAnimado(
            chave: _versao,
            altura: 240,
            descricaoAcessivel:
                'Gráfico de barras de gastos por categoria: ${dados.porCategoria.map((categoria) => '${categoria.nome} ${Formatadores.moeda(categoria.totalCentavos)}').join(', ')}',
            painter: (progresso) => BarrasPainter([
              for (final categoria in dados.porCategoria.take(7))
                ItemBarra(
                  categoria.nome,
                  categoria.totalCentavos / 100,
                  Color(categoria.cor),
                ),
            ], progresso: progresso),
          ),
  );

  Widget _cartaoUltimos(DadosInicio dados) => CartaoSecao(
    titulo: 'Últimos lançamentos',
    acao: TextButton(
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LancamentosView())),
      child: const Text('Ver todos', style: TextStyle(color: Cores.textoSuave)),
    ),
    child: dados.ultimos.isEmpty
        ? EstadoVazio(
            icone: Icons.receipt_long_outlined,
            titulo: 'Nada por aqui ainda',
            mensagem:
                'Toque no + para registrar sua primeira receita ou despesa.',
            acao: OutlinedButton.icon(
              onPressed: () => LancamentoFormView.abrir(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo lançamento'),
            ),
          )
        : Column(
            children: [
              for (final lancamento in dados.ultimos)
                ItemLancamento(
                  lancamento,
                  onTap: () =>
                      LancamentoFormView.abrir(context, editar: lancamento),
                ),
            ],
          ),
  );
}

class _Cabecalho extends StatelessWidget {
  final String? nome;
  final DadosInicio? dados;
  const _Cabecalho({required this.nome, required this.dados});

  @override
  Widget build(BuildContext context) {
    final totais = dados?.totais;
    final topo = MediaQuery.paddingOf(context).top;
    return ClipPath(
      clipper: _CurvaBase(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D6744), Color(0xFF28432F)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(10, topo + 18, 14, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BotaoMenu(key: ChavesTutorial.menu, cor: Colors.white),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome == null ? 'Olá!' : 'Olá, $nome',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        Formatadores.mesAno(DateTime.now()),
                        style: const TextStyle(color: Color(0xFFC9D6C3)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Categorias',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriasView()),
                  ),
                  icon: const Icon(Icons.sell_outlined, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'Perfil',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => PerfilDialog.abrir(context),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: nome == null
                          ? const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                            )
                          : Text(
                              nome!.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            // Alinha o saldo com a saudação (à direita do botão de menu).
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Rótulo + valor juntos: é esse bloco que o tutorial destaca.
                  Column(
                    key: ChavesTutorial.saldo,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo do mês',
                        style: TextStyle(
                          color: Color(0xFFC9D6C3),
                          fontSize: 15,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totais == null
                              ? '...'
                              : Formatadores.moeda(totais.saldo),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Pilula(
                        cor: Cores.verdeClaro,
                        rotulo: 'Receitas',
                        valor: totais?.receitas,
                      ),
                      const SizedBox(width: 10),
                      _Pilula(
                        cor: Cores.despesaClara,
                        rotulo: 'Despesas',
                        valor: totais?.despesas,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pilula extends StatelessWidget {
  final Color cor;
  final String rotulo;
  final int? valor;
  const _Pilula({required this.cor, required this.rotulo, this.valor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Bolinha(cor, tamanho: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: Color(0xFFC9D6C3),
                    fontSize: 12,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valor == null ? '...' : Formatadores.moeda(valor!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Borda inferior levemente curva do cabeçalho (Bézier quadrática).
class _CurvaBase extends CustomClipper<Path> {
  @override
  Path getClip(Size tamanho) => Path()
    ..lineTo(0, tamanho.height - 26)
    ..quadraticBezierTo(
      tamanho.width / 2,
      tamanho.height + 10,
      tamanho.width,
      tamanho.height - 26,
    )
    ..lineTo(tamanho.width, 0)
    ..close();

  @override
  bool shouldReclip(_CurvaBase oldClipper) => false;
}
