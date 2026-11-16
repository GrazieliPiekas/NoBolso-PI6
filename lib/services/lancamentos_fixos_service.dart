import '../database/lancamento_dao.dart';
import '../models/lancamento.dart';
import '../utils/formatadores.dart';

/// Lançamentos fixos (aluguel, salário, internet...): copia os do mês anterior
/// para o mês escolhido, para o usuário não precisar digitar tudo de novo.
class LancamentosFixosService {
  final LancamentoDao _dao;
  LancamentosFixosService([LancamentoDao? dao]) : _dao = dao ?? LancamentoDao();

  /// Copia os fixos do mês anterior a [mes] para dentro de [mes].
  /// Mantém o mesmo dia (dia 31 vira o último dia do mês, se ele for menor).
  /// Não duplica: se já existe um fixo com a mesma descrição, categoria e tipo
  /// no mês de destino, ele é pulado. Rodar duas vezes não cria nada novo.
  /// Devolve quantos lançamentos foram criados.
  Future<int> copiarDoMesAnterior(DateTime mes) async {
    final anterior = DateTime(mes.year, mes.month - 1, 1);
    final fixosAnteriores = (await _dao.listar(periodo: Periodo.mes(anterior)))
        .where((lancamento) => lancamento.fixo);

    final jaExistem = (await _dao.listar(periodo: Periodo.mes(mes)))
        .where((lancamento) => lancamento.fixo)
        .map(_chave)
        .toSet();

    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
    final novos = <Lancamento>[];
    for (final original in fixosAnteriores) {
      if (!jaExistem.add(_chave(original))) continue;
      final dia = original.data.day > ultimoDia ? ultimoDia : original.data.day;
      novos.add(
        Lancamento(
          descricao: original.descricao,
          valorCentavos: original.valorCentavos,
          tipo: original.tipo,
          categoriaId: original.categoriaId,
          data: DateTime(mes.year, mes.month, dia),
          fixo: true,
        ),
      );
    }
    if (novos.isNotEmpty) await _dao.inserirVarios(novos);
    return novos.length;
  }

  /// O que identifica "o mesmo" lançamento fixo de um mês para o outro.
  /// O valor fica de fora: se a conta de luz mudou de valor, continua sendo ela.
  static String _chave(Lancamento lancamento) =>
      '${lancamento.tipo.name}|${lancamento.categoriaId}|'
      '${lancamento.descricao.trim().toLowerCase()}';
}
