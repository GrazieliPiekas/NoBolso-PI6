import 'dart:math';

import '../database/categoria_dao.dart';
import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../models/tipo.dart';

/// Gera lançamentos fictícios para testes de desempenho e com participantes.
/// Só aparece em modo debug (no diálogo de perfil).
class GeradorDadosService {
  final CategoriaDao _categorias;
  final LancamentoDao _lancamentos;

  GeradorDadosService({CategoriaDao? categorias, LancamentoDao? lancamentos})
    : _categorias = categorias ?? CategoriaDao(),
      _lancamentos = lancamentos ?? LancamentoDao();

  static const _descricoes = {
    'Alimentação': ['Supermercado', 'Padaria', 'Restaurante', 'Feira', 'Lanche'],
    'Transporte': ['Combustível', 'Ônibus', 'Aplicativo de corrida', 'Estacionamento'],
    'Moradia': ['Aluguel', 'Conta de luz', 'Conta de água', 'Internet', 'Condomínio'],
    'Lazer': ['Cinema', 'Streaming', 'Show', 'Bar com amigos', 'Livro'],
    'Saúde': ['Farmácia', 'Consulta', 'Academia', 'Exame'],
    'Educação': ['Mensalidade', 'Material', 'Curso online'],
    'Salário': ['Salário'],
  };

  /// Insere [quantidade] lançamentos nos últimos 12 meses e devolve o tempo gasto.
  Future<Duration> gerar(int quantidade, {int? semente}) async {
    final rnd = Random(semente);
    final despesas = await _categorias.listar(tipo: Tipo.despesa);
    final receitas = await _categorias.listar(tipo: Tipo.receita);
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month - 11, 1);
    final dias = hoje.difference(inicio).inDays + 1;

    final itens = <Lancamento>[];
    // Cerca de 1 receita a cada 12 lançamentos, para o saldo ficar realista.
    for (var i = 0; i < quantidade; i++) {
      final data = inicio.add(Duration(days: rnd.nextInt(dias)));
      final receita = receitas.isNotEmpty && rnd.nextInt(12) == 0;
      final cat = receita
          ? receitas[rnd.nextInt(receitas.length)]
          : despesas[rnd.nextInt(despesas.length)];
      final opcoes = _descricoes[cat.nome] ?? ['${cat.nome} diverso'];
      // Fim de semana gasta um pouco mais: deixa o mapa de calor interessante.
      final fimDeSemana = data.weekday >= 6 ? 1.6 : 1.0;
      final valor = receita
          ? 150000 + rnd.nextInt(350000)
          : ((800 + rnd.nextInt(24000)) * fimDeSemana).round();
      itens.add(
        Lancamento(
          descricao: opcoes[rnd.nextInt(opcoes.length)],
          valorCentavos: valor,
          tipo: cat.tipo,
          categoriaId: cat.id!,
          data: data,
        ),
      );
    }
    final cronometro = Stopwatch()..start();
    await _lancamentos.inserirVarios(itens);
    cronometro.stop();
    return cronometro.elapsed;
  }
}
