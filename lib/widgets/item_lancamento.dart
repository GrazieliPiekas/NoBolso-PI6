import 'package:flutter/material.dart';

import '../models/lancamento.dart';
import '../models/tipo.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import 'componentes.dart';

class ItemLancamento extends StatelessWidget {
  final Lancamento lancamento;
  final VoidCallback? onTap;
  final bool mostrarData;

  const ItemLancamento(
    this.lancamento, {
    super.key,
    this.onTap,
    this.mostrarData = false,
  });

  @override
  Widget build(BuildContext context) {
    final receita = lancamento.tipo == Tipo.receita;
    final sub = [
      lancamento.categoriaNome ?? '',
      if (mostrarData) Formatadores.dataCurta(lancamento.data),
      if (lancamento.fixo) 'fixo',
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: lancamento.corCategoria.withValues(alpha: 0.15),
              child: Bolinha(lancamento.corCategoria),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lancamento.descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Cores.texto),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Cores.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatadores.moedaComSinal(
                lancamento.valorCentavos,
                positivo: receita,
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: receita ? Cores.verde : Cores.despesa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
