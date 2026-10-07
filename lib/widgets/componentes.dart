import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cartão claro com título e ação opcional à direita (padrão do protótipo).
class CartaoSecao extends StatelessWidget {
  final String? titulo;
  final Widget? acao;
  final Widget child;
  final EdgeInsets padding;

  const CartaoSecao({
    super.key,
    this.titulo,
    this.acao,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    padding: padding,
    decoration: BoxDecoration(
      color: Cores.cartao,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titulo != null || acao != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (titulo != null)
                  Expanded(
                    child: Text(
                      titulo!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ?acao,
              ],
            ),
          ),
        child,
      ],
    ),
  );
}

/// Texto suave à direita do título do cartão.
class RotuloSuave extends StatelessWidget {
  final String texto;
  const RotuloSuave(this.texto, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: const TextStyle(color: Cores.textoSuave, fontSize: 13),
  );
}

/// Cabeçalho das abas: título grande + subtítulo, fundo claro.
class CabecalhoTela extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget? acao;

  const CabecalhoTela({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.acao,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: Cores.cabecalho,
    padding: EdgeInsets.fromLTRB(
      24,
      MediaQuery.paddingOf(context).top + 18,
      12,
      18,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: const TextStyle(color: Cores.textoSuave, fontSize: 14),
              ),
            ],
          ),
        ),
        ?acao,
      ],
    ),
  );
}

/// Mensagem amigável quando ainda não há dados.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final Widget? acao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.acao,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
    child: Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Cores.verdeSuave,
          child: Icon(icone, color: Cores.verde),
        ),
        const SizedBox(height: 10),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.textoSuave),
        ),
        if (acao != null) ...[const SizedBox(height: 12), acao!],
      ],
    ),
  );
}

/// Faixa de aviso (amarela) ou informação (cinza), como no protótipo.
class Aviso extends StatelessWidget {
  final String titulo;
  final String? mensagem;
  final bool alerta;

  const Aviso({
    super.key,
    required this.titulo,
    this.mensagem,
    this.alerta = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: alerta ? Cores.alertaFundo : const Color(0xFFDFDCCF),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: alerta
              ? const Color(0xFFE0C4A0)
              : const Color(0xFFC3C9B6),
          child: Text(
            alerta ? '!' : 'i',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: alerta ? const Color(0xFF8A5A1E) : Cores.verde,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Cores.texto,
                ),
              ),
              if (mensagem != null) ...[
                const SizedBox(height: 2),
                Text(
                  mensagem!,
                  style: const TextStyle(
                    color: Cores.textoSuave,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Bolinha colorida de categoria.
class Bolinha extends StatelessWidget {
  final Color cor;
  final double tamanho;
  const Bolinha(this.cor, {super.key, this.tamanho = 12});
  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
  );
}

/// Barra de progresso arredondada (limites por categoria, resumo do período).
class BarraProgresso extends StatelessWidget {
  final double fracao;
  final Color cor;
  final double altura;
  const BarraProgresso({
    super.key,
    required this.fracao,
    required this.cor,
    this.altura = 10,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(altura),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fracao.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: altura,
        color: cor,
        backgroundColor: Cores.trilho,
      ),
    ),
  );
}

/// Indicador de carregamento padrão (RF10).
class Carregando extends StatelessWidget {
  const Carregando({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator(color: Cores.verde)),
  );
}
