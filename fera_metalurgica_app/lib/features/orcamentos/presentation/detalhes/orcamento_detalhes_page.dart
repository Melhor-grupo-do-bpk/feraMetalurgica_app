import 'package:fera_metalurgica_app/core/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Detalhes de um orçamento (Tela 6).
///
/// Stub criado na F1; implementado na trilha T2 (ações de WhatsApp na T5).
class OrcamentoDetalhesPage extends StatelessWidget {
  /// Cria a tela do orçamento [orcamentoId].
  const OrcamentoDetalhesPage({required this.orcamentoId, super.key});

  /// Identificador do orçamento exibido.
  final String orcamentoId;

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    titulo: 'Orçamento #$orcamentoId',
    onBack: () => context.pop(),
  );
}
