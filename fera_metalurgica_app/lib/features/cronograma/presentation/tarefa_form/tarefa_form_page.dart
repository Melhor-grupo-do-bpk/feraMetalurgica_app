import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefa_form/tarefa_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulário de criação/edição de tarefa (RF-86).
class TarefaFormPage extends ConsumerWidget {
  /// Cria o formulário. Com [tarefaId], edita a tarefa existente; com
  /// [orcamentoId], a tarefa nova já vem vinculada ao orçamento.
  const TarefaFormPage({this.tarefaId, this.orcamentoId, super.key});

  /// Tarefa em edição, ou `null` para uma tarefa nova.
  final String? tarefaId;

  /// Orçamento vinculado a uma tarefa nova ("Agendar" nos detalhes).
  final String? orcamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = tarefaId;
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: id == null
          ? TarefaForm(orcamentoIdInicial: orcamentoId)
          : switch (ref.watch(tarefaPorIdProvider(id))) {
              AsyncData(value: final Tarefa tarefa) => TarefaForm(
                inicial: tarefa,
              ),
              AsyncData() => const _Mensagem(texto: 'Tarefa não encontrada.'),
              AsyncError() => _Mensagem(
                texto: 'Não foi possível carregar a tarefa.',
                onTentarNovamente: () => ref.invalidate(tarefasProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, this.onTentarNovamente});

  final String texto;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedAppButton(
                label: 'Tentar novamente',
                icon: Icons.refresh,
                onPressed: onTentarNovamente,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
