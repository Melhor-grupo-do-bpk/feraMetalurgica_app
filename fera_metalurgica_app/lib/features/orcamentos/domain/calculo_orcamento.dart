import 'dart:math';

import 'package:fera_metalurgica_app/features/orcamentos/domain/custos_operacionais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';

/// Soma de todos os custos operacionais.
double calcularTotalCustos(CustosOperacionais custos) =>
    custos.materiaPrima +
    custos.maoDeObra +
    custos.insumos +
    custos.combustivel +
    custos.impostos;

/// Valor final cobrado do cliente: [totalCustos] acrescido de
/// [margemPercentual] (ex: `62.5` → total × 1,625).
double calcularValorFinal(double totalCustos, double margemPercentual) =>
    totalCustos * (1 + margemPercentual / 100);

/// Número do próximo orçamento (D-09): maior id numérico de [orcamentos]
/// mais 1, com 5 dígitos (ex: `"00483"`); `"00001"` se não houver nenhum.
String proximoIdOrcamento(List<Orcamento> orcamentos) {
  final maior = orcamentos.map((o) => int.tryParse(o.id) ?? 0).fold(0, max);
  return '${maior + 1}'.padLeft(5, '0');
}
