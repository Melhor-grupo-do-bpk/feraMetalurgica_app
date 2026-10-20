import 'package:fera_metalurgica_app/core/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Prévia do PDF de um orçamento (Tela 7).
///
/// Stub criado na F1; implementado na trilha T5.
class OrcamentoPdfPage extends StatelessWidget {
  /// Cria a prévia do orçamento [orcamentoId].
  const OrcamentoPdfPage({required this.orcamentoId, super.key});

  /// Identificador do orçamento.
  final String orcamentoId;

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    titulo: 'PDF do orçamento',
    onBack: () => context.pop(),
  );
}
