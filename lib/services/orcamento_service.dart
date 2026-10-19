import '../database/lancamento_dao.dart';
import '../database/orcamento_dao.dart';
import '../models/orcamento.dart';
import '../utils/formatadores.dart';
import 'notificacao_service.dart';

/// Usado e disponível de um orçamento no mês (RF04). Nada disso é guardado no banco.
class StatusOrcamento {
  final Orcamento orcamento;
  final int usado;
  const StatusOrcamento(this.orcamento, this.usado);

  int get limite => orcamento.limiteCentavos;
  int get disponivel => limite - usado;
  double get percentual => limite == 0 ? 0 : usado / limite;
  int get nivel => OrcamentoService.nivelAtingido(percentual);
}

/// Situação de todos os orçamentos do mês (o geral e os por categoria).
class ResumoOrcamentos {
  final StatusOrcamento? geral;
  final List<StatusOrcamento> categorias;

  const ResumoOrcamentos(this.geral, this.categorias);

  bool get vazio => geral == null && categorias.isEmpty;

  int get somaLimitesCategorias =>
      categorias.fold(0, (soma, item) => soma + item.limite);
  int get somaUsadoCategorias =>
      categorias.fold(0, (soma, item) => soma + item.usado);

  /// Decisão 3: o medidor mostra o geral; sem geral, usa a soma dos limites por categoria.
  bool get medidorPelaSoma => geral == null;
  int get limiteMedidor => geral?.limite ?? somaLimitesCategorias;
  int get usadoMedidor => geral?.usado ?? somaUsadoCategorias;
  double get percentualMedidor =>
      limiteMedidor == 0 ? 0 : usadoMedidor / limiteMedidor;

  /// Aviso informativo: soma das categorias maior que o orçamento geral.
  bool get somaExcedeGeral =>
      geral != null && somaLimitesCategorias > geral!.limite;
}

/// Regras de orçamento: quanto foi usado, quanto falta e quando avisar.
class OrcamentoService {
  final OrcamentoDao _orcamentos;
  final LancamentoDao _lancamentos;
  final NotificacaoService _notificacoes;

  OrcamentoService({
    OrcamentoDao? orcamentos,
    LancamentoDao? lancamentos,
    NotificacaoService? notificacoes,
  }) : _orcamentos = orcamentos ?? OrcamentoDao(),
       _lancamentos = lancamentos ?? LancamentoDao(),
       _notificacoes = notificacoes ?? NotificacaoService.instance;

  static const niveis = [50, 80, 100];

  /// Maior nível de alerta atingido: 100, 80, 50 ou 0 se ainda não chegou em 50%.
  static int nivelAtingido(double percentual) => percentual >= 1
      ? 100
      : percentual >= 0.8
      ? 80
      : percentual >= 0.5
      ? 50
      : 0;

  /// Calcula usado/disponível de cada orçamento no mês.
  /// O "usado" não fica salvo, é sempre somado na hora a partir dos lançamentos.
  Future<ResumoOrcamentos> resumo(DateTime mes) async {
    final periodo = Periodo.mes(mes);
    final lista = await _orcamentos.listar();
    StatusOrcamento? geral;
    final categorias = <StatusOrcamento>[];
    for (final orcamento in lista) {
      final usado = await _lancamentos.despesasDaCategoria(
        orcamento.categoriaId,
        periodo,
      );
      final status = StatusOrcamento(orcamento, usado);
      if (orcamento.geral) {
        geral = status;
      } else {
        categorias.add(status);
      }
    }
    return ResumoOrcamentos(geral, categorias);
  }

  /// Verifica os níveis 50/80/100% do mês atual e notifica cada nível uma única
  /// vez por mês por orçamento (decisão 4). Se o gasto pular de 40% para 100%,
  /// só o 100% é avisado e os níveis menores são marcados como enviados.
  /// Retorna as mensagens novas (a tela também pode exibi-las).
  Future<List<String>> verificarAlertas({DateTime? hoje}) async {
    final agora = hoje ?? DateTime.now();
    final referencia = Formatadores.referenciaMes(agora);
    final resumoDoMes = await resumo(agora);
    final mensagens = <String>[];
    for (final status in [?resumoDoMes.geral, ...resumoDoMes.categorias]) {
      final nivel = status.nivel;
      if (nivel == 0) continue;
      final enviados = await _orcamentos.niveisEnviados(
        status.orcamento.id!,
        referencia,
      );
      if (enviados.contains(nivel)) continue;
      for (final faixa in niveis.where((faixa) => faixa <= nivel)) {
        await _orcamentos.registrarAlerta(
          status.orcamento.id!,
          referencia,
          faixa,
        );
      }
      final (titulo, corpo) = mensagemAlerta(status, nivel);
      mensagens.add('$titulo. $corpo');
      await _notificacoes.mostrar(
        id: status.orcamento.id! * 1000 + nivel,
        titulo: titulo,
        corpo: corpo,
      );
    }
    return mensagens;
  }

  /// Tom claro e não punitivo (RF05).
  static (String, String) mensagemAlerta(StatusOrcamento status, int nivel) {
    final nome = status.orcamento.geral
        ? 'Seu orçamento do mês'
        : 'O orçamento de ${status.orcamento.nome}';
    final resta = Formatadores.moeda(status.disponivel.clamp(0, 1 << 62));
    return switch (nivel) {
      50 => (
        '$nome está na metade',
        'Você já usou ${(status.percentual * 100).round()}% e ainda restam $resta este mês.',
      ),
      80 => (
        '$nome chegou a ${(status.percentual * 100).round()}%',
        'Restam $resta até o fim do mês. Dá para ajustar com calma.',
      ),
      _ => (
        '$nome chegou ao limite',
        status.disponivel < 0
            ? 'Passou ${Formatadores.moeda(-status.disponivel)} do planejado. Tudo bem: você pode rever os próximos gastos ou ajustar o limite.'
            : 'Que tal rever os próximos gastos? Você pode ajustar o limite quando quiser.',
      ),
    };
  }
}
