import 'package:fera_metalurgica_app/core/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cronograma e agenda (Tela 10), aberto pela aba "Mais".
///
/// Stub criado na F1; implementado na trilha T7.
class CronogramaPage extends StatelessWidget {
  /// Cria a tela.
  const CronogramaPage({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderPage(titulo: 'Cronograma', onBack: () => context.pop());
}
