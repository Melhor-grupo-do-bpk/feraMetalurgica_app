import 'package:fera_metalurgica_app/core/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wizard de criação/edição de orçamento (Telas 2 a 5).
///
/// Stub criado na F1; implementado na trilha T3.
class OrcamentoWizardPage extends StatelessWidget {
  /// Cria o wizard. Com [orcamentoId], edita o orçamento existente; com
  /// [produtoId], começa um orçamento novo com esse produto do catálogo.
  const OrcamentoWizardPage({this.orcamentoId, this.produtoId, super.key});

  /// Orçamento em edição, ou `null` para um orçamento novo.
  final String? orcamentoId;

  /// Produto do catálogo que vira o primeiro item (RF-27), se houver.
  final String? produtoId;

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    titulo: orcamentoId == null ? 'Novo Orçamento' : 'Editar Orçamento',
    onBack: () => context.pop(),
  );
}
