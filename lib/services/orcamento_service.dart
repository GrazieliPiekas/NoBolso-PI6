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

class ResumoOrcamentos {
  final StatusOrcamento? geral;
  final List<StatusOrcamento> categorias;

  const ResumoOrcamentos(this.geral, this.categorias);

  bool get vazio => geral == null && categorias.isEmpty;

  int get somaLimitesCategorias =>
      categorias.fold(0, (s, c) => s + c.limite);
  int get somaUsadoCategorias => categorias.fold(0, (s, c) => s + c.usado);

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

  static int nivelAtingido(double p) => p >= 1
      ? 100
      : p >= 0.8
      ? 80
      : p >= 0.5
      ? 50
      : 0;

  Future<ResumoOrcamentos> resumo(DateTime mes) async {
    final periodo = Periodo.mes(mes);
    final lista = await _orcamentos.listar();
    StatusOrcamento? geral;
    final categorias = <StatusOrcamento>[];
    for (final o in lista) {
      final usado = await _lancamentos.despesasDaCategoria(
        o.categoriaId,
        periodo,
      );
      final s = StatusOrcamento(o, usado);
      if (o.geral) {
        geral = s;
      } else {
        categorias.add(s);
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
    final r = await resumo(agora);
    final mensagens = <String>[];
    for (final s in [?r.geral, ...r.categorias]) {
      final nivel = s.nivel;
      if (nivel == 0) continue;
      final enviados = await _orcamentos.niveisEnviados(
        s.orcamento.id!,
        referencia,
      );
      if (enviados.contains(nivel)) continue;
      for (final n in niveis.where((n) => n <= nivel)) {
        await _orcamentos.registrarAlerta(s.orcamento.id!, referencia, n);
      }
      final (titulo, corpo) = mensagemAlerta(s, nivel);
      mensagens.add('$titulo. $corpo');
      await _notificacoes.mostrar(
        id: s.orcamento.id! * 1000 + nivel,
        titulo: titulo,
        corpo: corpo,
      );
    }
    return mensagens;
  }

  /// Tom claro e não punitivo (RF05).
  static (String, String) mensagemAlerta(StatusOrcamento s, int nivel) {
    final nome = s.orcamento.geral
        ? 'Seu orçamento do mês'
        : 'O orçamento de ${s.orcamento.nome}';
    final resta = Formatadores.moeda(s.disponivel.clamp(0, 1 << 62));
    return switch (nivel) {
      50 => (
        '$nome está na metade',
        'Você já usou ${(s.percentual * 100).round()}% e ainda restam $resta este mês.',
      ),
      80 => (
        '$nome chegou a ${(s.percentual * 100).round()}%',
        'Restam $resta até o fim do mês. Dá para ajustar com calma.',
      ),
      _ => (
        '$nome chegou ao limite',
        s.disponivel < 0
            ? 'Passou ${Formatadores.moeda(-s.disponivel)} do planejado. Tudo bem: você pode rever os próximos gastos ou ajustar o limite.'
            : 'Que tal rever os próximos gastos? Você pode ajustar o limite quando quiser.',
      ),
    };
  }
}
