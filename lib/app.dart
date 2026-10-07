import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'database/configuracao_dao.dart';
import 'screens/abertura_screen.dart';
import 'screens/analise_screen.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/lancamento_form_screen.dart';
import 'screens/orcamentos_screen.dart';
import 'screens/relatorios_screen.dart';
import 'theme/app_theme.dart';

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
    home: const RaizScreen(),
  );
}

/// Mostra a abertura enquanto o banco é aberto e decide entre boas-vindas e o app.
class RaizScreen extends StatefulWidget {
  const RaizScreen({super.key});
  @override
  State<RaizScreen> createState() => _RaizScreenState();
}

class _RaizScreenState extends State<RaizScreen> {
  bool? _boasVindasVista;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final resultados = await Future.wait([
      ConfiguracaoDao().boasVindasVista(),
      // Deixa a marca visível por um instante, mesmo com o banco já pronto.
      Future.delayed(const Duration(milliseconds: 700), () => true),
    ]);
    if (mounted) setState(() => _boasVindasVista = resultados.first);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    child: switch (_boasVindasVista) {
      null => const AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: AberturaScreen(),
      ),
      false => AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: BoasVindasScreen(
          onConcluir: () => setState(() => _boasVindasVista = true),
        ),
      ),
      true => const NavegacaoPrincipal(),
    },
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
    InicioScreen(),
    AnaliseScreen(),
    OrcamentosScreen(),
    RelatoriosScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    // Ícones claros na barra de status sobre o cabeçalho verde do Início.
    body: AnnotatedRegion(
      value: _aba == 0 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: IndexedStack(index: _aba, children: _abas),
    ),
    bottomNavigationBar: _BarraInferior(
      aba: _aba,
      aoTrocar: (i) => setState(() => _aba = i),
      aoAdicionar: () => LancamentoFormScreen.abrir(context),
    ),
  );
}

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
