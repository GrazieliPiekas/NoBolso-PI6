import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../viewmodels/tutorial_view_model.dart';

/// Chaves colocadas nos widgets que o tutorial destaca. Com elas dá para
/// descobrir onde cada botão está na tela (posição e tamanho).
class ChavesTutorial {
  ChavesTutorial._();

  static final botaoNovo = GlobalKey(debugLabel: 'tutorial-botao-novo');
  static final saldo = GlobalKey(debugLabel: 'tutorial-saldo');
  static final abaOrcamento = GlobalKey(debugLabel: 'tutorial-aba-orcamento');
  static final abaRelatorios = GlobalKey(debugLabel: 'tutorial-aba-relatorios');
  static final menu = GlobalKey(debugLabel: 'tutorial-menu');

  static GlobalKey de(AlvoTutorial alvo) => switch (alvo) {
    AlvoTutorial.botaoNovo => botaoNovo,
    AlvoTutorial.saldo => saldo,
    AlvoTutorial.abaOrcamento => abaOrcamento,
    AlvoTutorial.abaRelatorios => abaRelatorios,
    AlvoTutorial.menu => menu,
  };
}

/// Tutorial do primeiro acesso: escurece a tela, destaca um botão e mostra
/// um balão explicando. Um toque em qualquer lugar passa para o próximo.
class TutorialView extends StatefulWidget {
  const TutorialView({super.key});

  /// Abre o tutorial por cima da tela atual (rota transparente, com fade).
  static Future<void> mostrar(BuildContext context) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, _, _) => const TutorialView(),
          transitionsBuilder: (_, animacao, _, filho) =>
              FadeTransition(opacity: animacao, child: filho),
        ),
      );

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = TutorialViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Retângulo do widget na tela, achado pela GlobalKey dele.
  /// null se o widget não estiver na tela.
  Rect? _areaDoAlvo(AlvoTutorial alvo) {
    final caixa = ChavesTutorial.de(alvo).currentContext?.findRenderObject();
    if (caixa is! RenderBox || !caixa.hasSize || !caixa.attached) return null;
    return caixa.localToGlobal(Offset.zero) & caixa.size;
  }

  Future<void> _avancar() async {
    final acabou = _viewModel.avancar();
    if (acabou) await _fechar();
  }

  Future<void> _fechar() async {
    await _viewModel.concluir();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _corpo(),
  );

  Widget _corpo() {
    final tela = MediaQuery.sizeOf(context);
    final passo = _viewModel.passoAtual;
    // Se o alvo não estiver na tela, o "buraco" fica no meio e sem tamanho.
    final area =
        _areaDoAlvo(passo.alvo) ??
        Rect.fromCenter(center: tela.center(Offset.zero), width: 0, height: 0);
    final destaque = area.inflate(8);

    // Balão embaixo do botão se ele estiver na metade de cima; senão, em cima.
    final balaoEmCima = destaque.center.dy > tela.height / 2;
    final largura = math.min(tela.width - 32, 300.0);
    final esquerda = (destaque.center.dx - largura / 2).clamp(
      16.0,
      tela.width - 16 - largura,
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _avancar,
        child: Stack(
          children: [
            // O "buraco" anda suavemente de um botão para o outro.
            Positioned.fill(
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: destaque),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (_, retangulo, _) => CustomPaint(
                  painter: _EscurecidoPainter(retangulo ?? destaque),
                ),
              ),
            ),
            Positioned(
              left: esquerda,
              width: largura,
              top: balaoEmCima ? null : destaque.bottom + 4,
              bottom: balaoEmCima ? tela.height - destaque.top + 4 : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _Balao(
                  key: ValueKey(_viewModel.indice),
                  texto: passo.texto,
                  contador: _viewModel.contador,
                  ultimo: _viewModel.ultimoPasso,
                  setaEmCima: !balaoEmCima,
                  setaX: destaque.center.dx - esquerda,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              right: 12,
              // Fundo claro para não sumir em cima do cabeçalho escuro.
              child: FilledButton(
                onPressed: _fechar,
                style: FilledButton.styleFrom(
                  backgroundColor: Cores.cartao,
                  foregroundColor: Cores.verde,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fonte,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Pular'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Balão de fala com uma setinha apontando para o botão destacado.
class _Balao extends StatelessWidget {
  final String texto;
  final String contador;
  final bool ultimo;
  final bool setaEmCima;

  /// Posição horizontal da ponta da seta, medida a partir da borda do balão.
  final double setaX;

  const _Balao({
    super.key,
    required this.texto,
    required this.contador,
    required this.ultimo,
    required this.setaEmCima,
    required this.setaX,
  });

  @override
  Widget build(BuildContext context) {
    final seta = SizedBox(
      height: 10,
      width: double.infinity,
      child: CustomPaint(
        painter: _SetaPainter(setaX, apontaParaCima: setaEmCima),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (setaEmCima) seta,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          decoration: BoxDecoration(
            color: Cores.cartao,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  color: Cores.texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    contador,
                    style: const TextStyle(
                      color: Cores.textoSuave,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ultimo ? 'Toque para começar' : 'Toque para continuar',
                    style: const TextStyle(
                      color: Cores.verde,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!setaEmCima) seta,
      ],
    );
  }
}

/// Tela escura com um "buraco" arredondado em volta do botão destacado.
/// O truque é o PathFillType.evenOdd: o retângulo da tela e o do botão
/// ficam no mesmo Path, e a parte onde os dois se sobrepõem não é pintada.
class _EscurecidoPainter extends CustomPainter {
  final Rect destaque;
  _EscurecidoPainter(this.destaque);

  @override
  void paint(Canvas canvas, Size size) {
    final raio = math.min(20.0, destaque.shortestSide / 2);
    final buraco = RRect.fromRectAndRadius(destaque, Radius.circular(raio));
    final fundo = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(buraco);
    canvas.drawPath(fundo, Paint()..color = const Color(0xB3000000));
    canvas.drawRRect(
      buraco,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Cores.creme,
    );
  }

  @override
  bool shouldRepaint(_EscurecidoPainter anterior) =>
      anterior.destaque != destaque;
}

/// Triângulo pequeno que liga o balão ao botão.
class _SetaPainter extends CustomPainter {
  final double pontaX;
  final bool apontaParaCima;
  _SetaPainter(this.pontaX, {required this.apontaParaCima});

  @override
  void paint(Canvas canvas, Size size) {
    // Não deixa a seta sair das bordas arredondadas do balão.
    final x = pontaX.clamp(24.0, size.width - 24);
    final seta = Path();
    if (apontaParaCima) {
      seta
        ..moveTo(x, 0)
        ..lineTo(x - 10, size.height)
        ..lineTo(x + 10, size.height);
    } else {
      seta
        ..moveTo(x, size.height)
        ..lineTo(x - 10, 0)
        ..lineTo(x + 10, 0);
    }
    canvas.drawPath(seta..close(), Paint()..color = Cores.cartao);
  }

  @override
  bool shouldRepaint(_SetaPainter anterior) =>
      anterior.pontaX != pontaX || anterior.apontaParaCima != apontaParaCima;
}
