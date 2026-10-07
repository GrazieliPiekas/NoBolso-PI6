import 'package:flutter/material.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../widgets/componentes.dart';
import '../widgets/item_lancamento.dart';
import 'lancamento_form_screen.dart';

/// Lista completa com filtros de período (mês), tipo e categoria. Toque para editar,
/// arraste para a esquerda para excluir.
class LancamentosScreen extends StatefulWidget {
  const LancamentosScreen({super.key});
  @override
  State<LancamentosScreen> createState() => _LancamentosScreenState();
}

class _LancamentosScreenState extends State<LancamentosScreen> {
  final _dao = LancamentoDao();
  DateTime _mes = DateTime.now();
  Tipo? _tipo;
  int? _categoriaId;
  List<Categoria> _categorias = [];
  List<Lancamento>? _itens;
  Totais? _totais;

  @override
  void initState() {
    super.initState();
    Eventos.dadosAlterados.addListener(_carregar);
    CategoriaDao().listar().then((c) {
      if (mounted) setState(() => _categorias = c);
    });
    _carregar();
  }

  @override
  void dispose() {
    Eventos.dadosAlterados.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    final p = Periodo.mes(_mes);
    final itens = await _dao.listar(
      periodo: p,
      tipo: _tipo,
      categoriaId: _categoriaId,
    );
    final totais = await _dao.totais(
      periodo: p,
      tipo: _tipo,
      categoriaId: _categoriaId,
    );
    if (mounted) {
      setState(() {
        _itens = itens;
        _totais = totais;
      });
    }
  }

  void _mudarMes(int delta) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + delta, 1);
      _itens = null;
    });
    _carregar();
  }

  Future<bool> _confirmarExclusao(Lancamento l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('"${l.descricao}" de ${Formatadores.moeda(l.valorCentavos)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Cores.despesa),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categorias
        .where((c) => _tipo == null || c.tipo == _tipo)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamentos')),
      body: Column(
        children: [
          Container(
            color: Cores.cabecalho,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Mês anterior',
                      onPressed: () => _mudarMes(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        Formatadores.mesAno(_mes),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Próximo mês',
                      onPressed: () => _mudarMes(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      for (final t in [null, Tipo.receita, Tipo.despesa])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t?.rotuloPlural ?? 'Todos'),
                            selected: _tipo == t,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                      fontFamily: AppTheme.fonte,
                              color: _tipo == t ? Colors.white : Cores.texto,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _tipo = t;
                                _categoriaId = null;
                              });
                              _carregar();
                            },
                          ),
                        ),
                      DropdownButton<int?>(
                        value: _categoriaId,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(16),
                        hint: const Text('Categoria'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todas as categorias'),
                          ),
                          for (final c in cats)
                            DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Bolinha(c.color),
                                  const SizedBox(width: 8),
                                  Text(
                                    _tipo == null
                                        ? '${c.nome} (${c.tipo.rotulo.toLowerCase()})'
                                        : c.nome,
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() => _categoriaId = v);
                          _carregar();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_totais != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${_totais!.quantidade} lançamento${_totais!.quantidade == 1 ? '' : 's'}',
                    style: const TextStyle(color: Cores.textoSuave),
                  ),
                  const Spacer(),
                  Text(
                    'Saldo: ${Formatadores.moeda(_totais!.saldo)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    final itens = _itens;
    if (itens == null) return const Carregando();
    if (itens.isEmpty) {
      return const EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Nenhum lançamento',
        mensagem: 'Não há lançamentos com esses filtros neste mês.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: itens.length,
      itemBuilder: (context, i) {
        final l = itens[i];
        return Dismissible(
          key: ValueKey(l.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmarExclusao(l),
          onDismissed: (_) async {
            setState(() => itens.removeAt(i));
            await _dao.excluir(l.id!);
            Eventos.notificarDados();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lançamento excluído')),
              );
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Cores.despesa,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Cores.cartao,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ItemLancamento(
              l,
              mostrarData: true,
              onTap: () => LancamentoFormScreen.abrir(context, editar: l),
            ),
          ),
        );
      },
    );
  }
}
