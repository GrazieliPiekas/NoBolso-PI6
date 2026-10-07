import 'package:flutter/material.dart';

import '../database/categoria_dao.dart';
import '../models/categoria.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/validadores.dart';

/// Criar / editar categoria. Devolve a categoria salva (com id) ou null.
class CategoriaFormDialog extends StatefulWidget {
  final Categoria? editar;
  final Tipo? tipoFixo;

  const CategoriaFormDialog({super.key, this.editar, this.tipoFixo});

  static Future<Categoria?> abrir(
    BuildContext context, {
    Categoria? editar,
    Tipo? tipoFixo,
  }) => showDialog<Categoria>(
    context: context,
    builder: (_) => CategoriaFormDialog(editar: editar, tipoFixo: tipoFixo),
  );

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  final _dao = CategoriaDao();
  late final _nome = TextEditingController(text: widget.editar?.nome);
  late Tipo _tipo = widget.editar?.tipo ?? widget.tipoFixo ?? Tipo.despesa;
  late int _cor =
      widget.editar?.cor ?? Cores.paletaCategorias[2].toARGB32();
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final erro = Validadores.nomeCategoria(_nome.text);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    setState(() => _salvando = true);
    final c = Categoria(
      id: widget.editar?.id,
      nome: _nome.text.trim(),
      tipo: _tipo,
      cor: _cor,
    );
    try {
      Categoria salva;
      if (c.id == null) {
        salva = c.copyWith(id: await _dao.inserir(c));
      } else {
        await _dao.atualizar(c);
        salva = c;
      }
      Eventos.notificarDados();
      if (mounted) Navigator.pop(context, salva);
    } catch (e) {
      setState(() {
        _salvando = false;
        _erro = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.editar == null ? 'Nova categoria' : 'Editar categoria'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nome,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Nome', errorText: _erro),
            onChanged: (_) {
              if (_erro != null) setState(() => _erro = null);
            },
          ),
          if (widget.tipoFixo == null) ...[
            const SizedBox(height: 4),
            SegmentedButton<Tipo>(
              segments: const [
                ButtonSegment(value: Tipo.despesa, label: Text('Despesa')),
                ButtonSegment(value: Tipo.receita, label: Text('Receita')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Cor', style: TextStyle(color: Cores.textoSuave)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final cor in Cores.paletaCategorias)
                Semantics(
                  selected: cor.toARGB32() == _cor,
                  button: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _cor = cor.toARGB32()),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cor.toARGB32() == _cor
                              ? Cores.texto
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: cor.toARGB32() == _cor
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(
        onPressed: _salvando ? null : _salvar,
        child: const Text('Salvar'),
      ),
    ],
  );
}
