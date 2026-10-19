import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/perfil_dialog.dart';
import 'abertura_view.dart';
import 'categorias_view.dart';
import 'lancamentos_view.dart';
import 'sobre_view.dart';

/// Menu lateral (Flyout): atalhos para as telas que não estão na barra inferior.
class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    void abrir(Widget tela) {
      Navigator.pop(context); // fecha o Drawer
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    }

    return Drawer(
      backgroundColor: Cores.fundo,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(gradient: degradeVerde),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/icone_nobolso.png',
                    width: 64,
                    height: 64,
                    semanticLabel: 'Logo do NoBolso',
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '.nobolso',
                        style: TextStyle(
                          color: Cores.creme,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'suas finanças, no seu bolso',
                        style: TextStyle(
                          color: Color(0xFFC9CDB8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.receipt_long_outlined,
              color: Cores.verde,
            ),
            title: const Text('Lançamentos'),
            onTap: () => abrir(const LancamentosView()),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined, color: Cores.verde),
            title: const Text('Categorias'),
            onTap: () => abrir(const CategoriasView()),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Cores.verde),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              PerfilDialog.abrir(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Cores.verde),
            title: const Text('Sobre o NoBolso'),
            onTap: () => abrir(const SobreView()),
          ),
        ],
      ),
    );
  }
}
