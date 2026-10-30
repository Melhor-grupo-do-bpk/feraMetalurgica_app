import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botão "Agendar" dos detalhes do orçamento (v2-plano §6, item 3): abre o
/// formulário de tarefa já vinculado ao orçamento [orcamentoId]. A V2-D
/// posiciona; a V2-E implementa.
// TODO(V2-E): título preenchido (ex: "Produção 281026-03").
class AgendarTarefaButton extends StatelessWidget {
  /// Cria o botão para o orçamento [orcamentoId].
  const AgendarTarefaButton({required this.orcamentoId, super.key});

  /// Id do orçamento que a tarefa nova recebe.
  final String orcamentoId;

  @override
  Widget build(BuildContext context) => OutlinedAppButton(
    label: 'Agendar',
    icon: Icons.event_outlined,
    onPressed: () => context.push(AppRoutes.tarefa(orcamentoId: orcamentoId)),
  );
}
