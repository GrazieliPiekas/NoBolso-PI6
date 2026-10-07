import 'package:flutter/material.dart';

import '../database/categoria_dao.dart';
import '../database/orcamento_dao.dart';
import '../models/categoria.dart';
import '../models/orcamento.dart';
import '../models/tipo.dart';
import '../services/notificacao_service.dart';
import '../services/orcamento_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../utils/moeda_input_formatter.dart';
import '../utils/validadores.dart';
import '../widgets/componentes.dart';

/// Formulário de orçamento mensal recorrente: geral ou de uma categoria de despesa.
class OrcamentoFormSheet extends StatefulWidget {
  final Orcamento? editar;
  final bool geral;
  const OrcamentoFormSheet({super.key, this.editar, this.geral = false});

  static Future<void> abrir(
    BuildContext context, {
    Orcamento? editar,
    bool geral = false,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => OrcamentoFormSheet(editar: editar, geral: geral),
  );

  @override
  State<OrcamentoFormSheet> createState() => _OrcamentoFormSheetState();
}

/// Valor do dropdown: -1 representa o orçamento geral (categoria_id NULL).
const _geral = -1;

class _OrcamentoFormSheetState extends State<OrcamentoFormSheet> {
  final _dao = OrcamentoDao();
  final _limite = TextEditingController();
  List<Categoria> _opcoes = [];
  bool _geralDisponivel = true;
  int? _alvo;
  String? _erro;
  bool _salvando = false;

  bool get _edicao => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    if (e != null) {
      _limite.text = MoedaInputFormatter.formatar(e.limiteCentavos);
      _alvo = e.categoriaId ?? _geral;
    } else if (widget.geral) {
      _alvo = _geral;
    }
    _carregar();
  }

  @override
  void dispose() {
    _limite.dispose();
    super.dispose();
  }

  /// Só oferece categorias de despesa que ainda não têm orçamento.
  Future<void> _carregar() async {
    final existentes = await _dao.listar();
    final usadas = existentes
        .where((o) => o.id != widget.editar?.id)
        .map((o) => o.categoriaId)
        .toSet();
    final cats = await CategoriaDao().listar(tipo: Tipo.despesa);
    if (!mounted) return;
    setState(() {
      _geralDisponivel = !usadas.contains(null);
      _opcoes = cats.where((c) => !usadas.contains(c.id)).toList();
      _alvo ??= _geralDisponivel
          ? _geral
          : (_opcoes.isEmpty ? null : _opcoes.first.id);
    });
  }

  Future<void> _salvar() async {
    final erroValor = Validadores.valor(_limite.text);
    if (_alvo == null || erroValor != null) {
      setState(() => _erro = erroValor ?? 'Escolha a que o orçamento se aplica');
      return;
    }
    setState(() => _salvando = true);
    final o = Orcamento(
      id: widget.editar?.id,
      categoriaId: _alvo == _geral ? null : _alvo,
      limiteCentavos: Formatadores.centavosDeTexto(_limite.text)!,
    );
    try {
      if (_edicao) {
        await _dao.atualizar(o);
      } else {
        await _dao.inserir(o);
      }
      await NotificacaoService.instance.pedirPermissao();
      final alertas = await OrcamentoService().verificarAlertas();
      Eventos.notificarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(['Orçamento salvo', ...alertas].join('\n'))),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _salvando = false;
        _erro = e.toString();
      });
    }
  }

  Future<void> _excluir() async {
    await _dao.excluir(widget.editar!.id!);
    Eventos.notificarDados();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Orçamento removido')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _edicao ? 'Editar orçamento' : 'Novo orçamento mensal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vale para todos os meses; você pode mudar quando quiser.',
          style: TextStyle(color: Cores.textoSuave, fontSize: 13),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
          initialValue: _alvo,
          decoration: const InputDecoration(labelText: 'Aplicar a'),
          items: [
            if (_geralDisponivel)
              const DropdownMenuItem(
                value: _geral,
                child: Text('Orçamento geral do mês'),
              ),
            for (final c in _opcoes)
              DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Bolinha(c.color),
                    const SizedBox(width: 8),
                    Text(c.nome),
                  ],
                ),
              ),
          ],
          onChanged: _edicao ? null : (v) => setState(() => _alvo = v),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _limite,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [MoedaInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Limite por mês',
            prefixText: r'R$ ',
            errorText: _erro,
          ),
          onChanged: (_) {
            if (_erro != null) setState(() => _erro = null);
          },
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar orçamento'),
        ),
        if (_edicao)
          TextButton(
            onPressed: _salvando ? null : _excluir,
            style: TextButton.styleFrom(foregroundColor: Cores.despesa),
            child: const Text('Remover orçamento'),
          ),
      ],
    ),
  );
}
