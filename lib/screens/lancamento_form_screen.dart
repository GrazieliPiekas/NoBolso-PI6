import 'package:flutter/material.dart';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../services/orcamento_service.dart';
import '../theme/app_theme.dart';
import '../utils/eventos.dart';
import '../utils/formatadores.dart';
import '../utils/moeda_input_formatter.dart';
import '../utils/validadores.dart';
import '../widgets/componentes.dart';
import 'categoria_form_dialog.dart';

/// Novo / editar lançamento. Fluxo curto (RF12): tipo → valor → categoria → salvar;
/// data já vem como hoje e a descrição é sugerida pela categoria se ficar vazia.
class LancamentoFormScreen extends StatefulWidget {
  final Lancamento? editar;
  const LancamentoFormScreen({super.key, this.editar});

  static Future<void> abrir(BuildContext context, {Lancamento? editar}) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => LancamentoFormScreen(editar: editar),
        ),
      );

  @override
  State<LancamentoFormScreen> createState() => _LancamentoFormScreenState();
}

class _LancamentoFormScreenState extends State<LancamentoFormScreen> {
  final _categoriasDao = CategoriaDao();
  final _dao = LancamentoDao();
  final _valor = TextEditingController();
  final _descricao = TextEditingController();

  late Tipo _tipo;
  int? _categoriaId;
  late DateTime _data;
  List<Categoria> _categorias = [];
  bool _carregando = true;
  bool _salvando = false;
  String? _erroValor;
  String? _erroCategoria;

  bool get _edicao => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    _tipo = e?.tipo ?? Tipo.despesa;
    _categoriaId = e?.categoriaId;
    _data = e?.data ?? DateTime.now();
    if (e != null) {
      _valor.text = MoedaInputFormatter.formatar(e.valorCentavos);
      _descricao.text = e.descricao;
    }
    _carregarCategorias();
  }

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    final lista = await _categoriasDao.listar(tipo: _tipo);
    if (!mounted) return;
    setState(() {
      _categorias = lista;
      _carregando = false;
      if (!lista.any((c) => c.id == _categoriaId)) _categoriaId = null;
    });
  }

  void _trocarTipo(Tipo t) {
    if (t == _tipo) return;
    setState(() {
      _tipo = t;
      _categoriaId = null;
      _erroCategoria = null;
    });
    _carregarCategorias();
  }

  Future<void> _novaCategoria() async {
    final nova = await CategoriaFormDialog.abrir(context, tipoFixo: _tipo);
    if (nova == null) return;
    await _carregarCategorias();
    setState(() {
      _categoriaId = nova.id;
      _erroCategoria = null;
    });
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _salvar() async {
    // RF11: valida valor e categoria antes de salvar.
    setState(() {
      _erroValor = Validadores.valor(_valor.text);
      _erroCategoria = Validadores.categoria(_categoriaId);
    });
    if (_erroValor != null || _erroCategoria != null) return;

    final categoria = _categorias.firstWhere((c) => c.id == _categoriaId);
    final descricao = _descricao.text.trim().isEmpty
        ? categoria.nome
        : _descricao.text.trim();
    final l = Lancamento(
      id: widget.editar?.id,
      descricao: descricao,
      valorCentavos: Formatadores.centavosDeTexto(_valor.text)!,
      tipo: _tipo,
      categoriaId: _categoriaId!,
      data: _data,
    );

    setState(() => _salvando = true);
    try {
      if (_edicao) {
        await _dao.atualizar(l);
      } else {
        await _dao.inserir(l);
      }
      final alertas = await OrcamentoService().verificarAlertas();
      Eventos.notificarDados();
      if (!mounted) return;
      // RF10: confirmação visível.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            [
              _edicao ? 'Lançamento atualizado' : 'Lançamento salvo',
              ...alertas,
            ].join('\n'),
          ),
          duration: Duration(seconds: alertas.isEmpty ? 2 : 5),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $e')),
      );
    }
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text('Essa ação não pode ser desfeita.'),
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
    if (ok != true) return;
    await _dao.excluir(widget.editar!.id!);
    Eventos.notificarDados();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lançamento excluído')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final corTipo = _tipo == Tipo.despesa ? Cores.despesa : Cores.verde;
    return Scaffold(
      backgroundColor: Cores.cabecalho,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_edicao ? 'Editar lançamento' : 'Novo lançamento'),
        actions: [
          if (_edicao)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _salvando ? null : _excluir,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _SeletorTipo(tipo: _tipo, aoTrocar: _trocarTipo),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Valor',
                      style: TextStyle(color: Cores.textoSuave, fontSize: 15),
                    ),
                  ),
                  // "R$" colado ao número e o conjunto centralizado.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        r'R$ ',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Cores.texto,
                        ),
                      ),
                      Flexible(
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _valor,
                            autofocus: !_edicao,
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoedaInputFormatter()],
                            onChanged: (_) => setState(() => _erroValor = null),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Cores.texto,
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              isDense: true,
                              hintText: '0,00',
                              hintStyle: TextStyle(color: Cores.textoSuave),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    color: _erroValor != null
                        ? Cores.despesa
                        : _valor.text.isEmpty
                        ? Cores.trilho
                        : corTipo.withValues(alpha: 0.5),
                  ),
                  if (_erroValor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _erroValor!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Cores.despesa,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  const Text(
                    'Categoria',
                    style: TextStyle(
                      color: Cores.textoSuave,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_carregando)
                    const LinearProgressIndicator(color: Cores.verde)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _categorias)
                          _ChipCategoria(
                            rotulo: c.nome,
                            cor: c.color,
                            selecionado: c.id == _categoriaId,
                            onTap: () => setState(() {
                              _categoriaId = c.id;
                              _erroCategoria = null;
                            }),
                          ),
                        _ChipCategoria(
                          rotulo: '+ Nova',
                          cor: Cores.textoSuave,
                          selecionado: false,
                          onTap: _novaCategoria,
                        ),
                      ],
                    ),
                  if (_erroCategoria != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _erroCategoria!,
                        style: const TextStyle(
                          color: Cores.despesa,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  _CampoToque(
                    rotulo: 'Data',
                    valor: Formatadores.dataLonga(_data),
                    onTap: _escolherData,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricao,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Ex.: Supermercado São José',
                      contentPadding: EdgeInsets.fromLTRB(20, 18, 20, 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
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
                    : Text(_edicao ? 'Salvar alterações' : 'Salvar lançamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeletorTipo extends StatelessWidget {
  final Tipo tipo;
  final ValueChanged<Tipo> aoTrocar;
  const _SeletorTipo({required this.tipo, required this.aoTrocar});

  @override
  Widget build(BuildContext context) {
    Widget opcao(Tipo t, Color cor) {
      final ativo = t == tipo;
      return Expanded(
        child: Semantics(
          selected: ativo,
          button: true,
          child: GestureDetector(
            onTap: () => aoTrocar(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ativo ? cor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                t.rotulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w400,
                  color: ativo ? Colors.white : Cores.textoSuave,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          opcao(Tipo.despesa, Cores.despesa),
          opcao(Tipo.receita, Cores.verde),
        ],
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String rotulo;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  const _ChipCategoria({
    required this.rotulo,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selecionado,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? cor : Cores.cartao,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selecionado ? cor : Cores.trilho,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Bolinha(selecionado ? Colors.white : cor),
            const SizedBox(width: 8),
            Text(
              rotulo,
              style: TextStyle(
                color: selecionado ? Colors.white : Cores.texto,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Campo que abre um seletor ao tocar (Data), no estilo do protótipo.
class _CampoToque extends StatelessWidget {
  final String rotulo;
  final String valor;
  final VoidCallback onTap;

  const _CampoToque({
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Cores.campo,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: const TextStyle(
                      color: Cores.textoSuave,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(valor, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Cores.textoSuave),
          ],
        ),
      ),
    ),
  );
}
