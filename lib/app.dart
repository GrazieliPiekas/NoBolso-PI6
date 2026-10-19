import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'viewmodels/raiz_view_model.dart';
import 'views/abertura_view.dart';
import 'views/analise_view.dart';
import 'views/boas_vindas_view.dart';
import 'views/inicio_view.dart';
import 'views/lancamento_form_view.dart';
import 'views/menu_lateral.dart';
import 'views/orcamentos_view.dart';
import 'views/relatorios_view.dart';

/// Widget raiz do app: tema, idioma pt-BR e a primeira tela (RaizView).
class NoBolsoApp extends StatelessWidget {
  const NoBolsoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NoBolso',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.claro,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const RaizView(),
  );
}

/// Mostra a abertura enquanto o banco é aberto e decide entre boas-vindas e o app.
class RaizView extends StatefulWidget {
  const RaizView({super.key});
  @override
  State<RaizView> createState() => _RaizViewState();
}

class _RaizViewState extends State<RaizView> {
  // ViewModel da tela (MVVM): guarda os dados e faz as ações.
  // A tela só desenha, e o ListenableBuilder redesenha quando ele avisa.
  final _viewModel = RaizViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (_viewModel.boasVindasVista) {
        null => const AnnotatedRegion(
          value: SystemUiOverlayStyle.light,
          child: AberturaView(),
        ),
        false => AnnotatedRegion(
          value: SystemUiOverlayStyle.light,
          child: BoasVindasView(onConcluir: _viewModel.boasVindasConcluidas),
        ),
        true => const NavegacaoPrincipal(),
      },
    ),
  );
}

/// Navegação inferior: Início · Análise · (+) · Orçamentos · Relatórios.
class NavegacaoPrincipal extends StatefulWidget {
  const NavegacaoPrincipal({super.key});
  @override
  State<NavegacaoPrincipal> createState() => _NavegacaoPrincipalState();
}

class _NavegacaoPrincipalState extends State<NavegacaoPrincipal> {
  int _aba = 0;

  static const _abas = <Widget>[
    InicioView(),
    AnaliseView(),
    OrcamentosView(),
    RelatoriosView(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const MenuLateral(),
    // Ícones claros na barra de status sobre o cabeçalho verde do Início.
    body: AnnotatedRegion(
      value: _aba == 0 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: IndexedStack(index: _aba, children: _abas),
    ),
    bottomNavigationBar: _BarraInferior(
      aba: _aba,
      aoTrocar: (i) => setState(() => _aba = i),
      aoAdicionar: () => LancamentoFormView.abrir(context),
    ),
  );
}

/// Barra de baixo com as 4 abas e o botão + no meio para lançar rápido.
class _BarraInferior extends StatelessWidget {
  final int aba;
  final ValueChanged<int> aoTrocar;
  final VoidCallback aoAdicionar;

  const _BarraInferior({
    required this.aba,
    required this.aoTrocar,
    required this.aoAdicionar,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icone, IconData iconeAtivo, String rotulo) {
      final ativo = aba == i;
      final cor = ativo ? Cores.verde : Cores.textoSuave;
      return Expanded(
        child: InkWell(
          onTap: () => aoTrocar(i),
          child: Semantics(
            selected: ativo,
            button: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ativo ? iconeAtivo : icone, color: cor),
                const SizedBox(height: 4),
                Text(
                  rotulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: cor,
                    fontWeight: ativo ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Cores.cartao,
        border: Border(top: BorderSide(color: Cores.trilho)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              item(0, Icons.home_outlined, Icons.home, 'Início'),
              item(1, Icons.insights_outlined, Icons.insights, 'Análise'),
              Expanded(
                child: Center(
                  child: Semantics(
                    label: 'Novo lançamento',
                    button: true,
                    child: Material(
                      color: Cores.verde,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: aoAdicionar,
                        child: const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(Icons.add, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              item(2, Icons.savings_outlined, Icons.savings, 'Orçamento'),
              item(
                3,
                Icons.description_outlined,
                Icons.description,
                'Relatórios',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
