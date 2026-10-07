import 'package:flutter/material.dart';

import '../database/configuracao_dao.dart';
import '../painters/barras_painter.dart';
import '../painters/rosca_painter.dart';
import '../services/dados_graficos_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_animado.dart';
import '../widgets/item_lancamento.dart';
import '../widgets/perfil_dialog.dart';
import 'categorias_screen.dart';
import 'lancamento_form_screen.dart';
import 'lancamentos_screen.dart';

/// Painel: saldo do mês, rosca (receitas × despesas), barras (gastos por categoria)
/// e últimos lançamentos.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _servico = DadosGraficosService();
  final _config = ConfiguracaoDao();
  DadosInicio? _dados;
  String? _nome;
  int _versao = 0;

  @override
  void initState() {
    super.initState();
    Eventos.dadosAlterados.addListener(_carregar);
    Eventos.perfilAlterado.addListener(_carregarNome);
    _carregar();
    _carregarNome();
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(_carregar);
    Eventos.perfilAlterado.removeListener(_carregarNome);
    super.dispose();
  }

  Future<void> _carregar() async {
    final d = await _servico.inicio(DateTime.now());
    if (mounted) {
      setState(() {
        _dados = d;
        _versao++;
      });
    }
  }

  Future<void> _carregarNome() async {
    final n = await _config.nomeUsuario();
    if (mounted) setState(() => _nome = n);
  }

  @override
  Widget build(BuildContext context) {
    final d = _dados;
    return RefreshIndicator(
      color: Cores.verde,
      onRefresh: _carregar,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cabecalho(nome: _nome, dados: d),
          const SizedBox(height: 18),
          if (d == null)
            const Carregando()
          else ...[
            _cartaoRosca(d),
            _cartaoBarras(d),
            _cartaoUltimos(d),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _cartaoRosca(DadosInicio d) {
    final t = d.totais;
    final total = t.receitas + t.despesas;
    String pct(int v) => total == 0 ? '0%' : '${(v * 100 / total).round()}%';
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
                  'Gráfico de rosca: receitas ${Formatadores.moeda(t.receitas)}, '
                  'despesas ${Formatadores.moeda(t.despesas)}',
              painter: (p) => RoscaPainter(
                [
                  FatiaRosca(t.receitas.toDouble(), Cores.verde),
                  FatiaRosca(t.despesas.toDouble(), Cores.despesaClara),
                ],
                textoCentro: Formatadores.moedaCurta(t.saldo),
                subtextoCentro: 'saldo',
                progresso: p,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _legenda(Cores.verde, 'Receitas', pct(t.receitas)),
                const SizedBox(height: 10),
                _legenda(Cores.despesaClara, 'Despesas', pct(t.despesas)),
                const SizedBox(height: 14),
                Text(
                  total == 0
                      ? 'Nenhum lançamento neste mês ainda.'
                      : t.receitas == 0
                      ? 'Sem receitas registradas no mês.'
                      : 'Você gastou ${(t.despesas * 100 / t.receitas).round()}% do que recebeu.',
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

  Widget _cartaoBarras(DadosInicio d) => CartaoSecao(
    titulo: 'Gastos por categoria',
    acao: const RotuloSuave('Este mês'),
    child: d.porCategoria.isEmpty
        ? const EstadoVazio(
            icone: Icons.bar_chart,
            titulo: 'Sem despesas este mês',
            mensagem: 'Quando você registrar gastos, eles aparecem aqui por categoria.',
          )
        : GraficoAnimado(
            chave: _versao,
            altura: 240,
            descricaoAcessivel:
                'Gráfico de barras de gastos por categoria: ${d.porCategoria.map((c) => '${c.nome} ${Formatadores.moeda(c.totalCentavos)}').join(', ')}',
            painter: (p) => BarrasPainter(
              [
                for (final c in d.porCategoria.take(7))
                  ItemBarra(c.nome, c.totalCentavos / 100, Color(c.cor)),
              ],
              progresso: p,
            ),
          ),
  );

  Widget _cartaoUltimos(DadosInicio d) => CartaoSecao(
    titulo: 'Últimos lançamentos',
    acao: TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LancamentosScreen()),
      ),
      child: const Text('Ver todos', style: TextStyle(color: Cores.textoSuave)),
    ),
    child: d.ultimos.isEmpty
        ? EstadoVazio(
            icone: Icons.receipt_long_outlined,
            titulo: 'Nada por aqui ainda',
            mensagem: 'Toque no + para registrar sua primeira receita ou despesa.',
            acao: OutlinedButton.icon(
              onPressed: () => LancamentoFormScreen.abrir(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo lançamento'),
            ),
          )
        : Column(
            children: [
              for (final l in d.ultimos)
                ItemLancamento(
                  l,
                  onTap: () => LancamentoFormScreen.abrir(context, editar: l),
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
    final t = dados?.totais;
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
        padding: EdgeInsets.fromLTRB(22, topo + 18, 14, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    MaterialPageRoute(builder: (_) => const CategoriasScreen()),
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
                          ? const Icon(Icons.person_outline, color: Colors.white)
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
            const SizedBox(height: 24),
            const Text(
              'Saldo do mês',
              style: TextStyle(color: Color(0xFFC9D6C3), fontSize: 15),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                t == null ? '...' : Formatadores.moeda(t.saldo),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Pilula(
                  cor: Cores.verdeClaro,
                  rotulo: 'Receitas',
                  valor: t?.receitas,
                ),
                const SizedBox(width: 10),
                _Pilula(
                  cor: Cores.despesaClara,
                  rotulo: 'Despesas',
                  valor: t?.despesas,
                ),
                const SizedBox(width: 8),
              ],
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
                  style: const TextStyle(color: Color(0xFFC9D6C3), fontSize: 12),
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
  Path getClip(Size s) => Path()
    ..lineTo(0, s.height - 26)
    ..quadraticBezierTo(s.width / 2, s.height + 10, s.width, s.height - 26)
    ..lineTo(s.width, 0)
    ..close();

  @override
  bool shouldReclip(_CurvaBase oldClipper) => false;
}
