import 'package:fera_metalurgica_app/core/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Formulário de criação/edição de tarefa (RF-86).
///
/// Stub criado na F1; implementado na trilha T7.
class TarefaFormPage extends StatelessWidget {
  /// Cria o formulário. Com [tarefaId], edita a tarefa existente.
  const TarefaFormPage({this.tarefaId, super.key});

  /// Tarefa em edição, ou `null` para uma tarefa nova.
  final String? tarefaId;

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    titulo: tarefaId == null ? 'Nova tarefa' : 'Editar tarefa',
    onBack: () => context.pop(),
  );
}
