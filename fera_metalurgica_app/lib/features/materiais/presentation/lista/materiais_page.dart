import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_ui.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lista de materiais, aberta por "Mais" (D-31). Stub da F2: lista todos
/// os materiais e abre o formulário para criar ou editar.
// TODO(V2-C): busca, filtro Ativos/Todos, inativar e reativar (prompt
// §3.1).
class MateriaisPage extends ConsumerWidget {
  /// Cria a tela.
  const MateriaisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo material',
        onPressed: () => context.push(AppRoutes.material()),
        child: const Icon(Icons.add),
      ),
      body: switch (ref.watch(materiaisProvider)) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Materiais',
              style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (value.isEmpty)
              Text(
                'Nenhum material cadastrado.',
                style: AppTextStyles.body.copyWith(color: colors.textSecondary),
              ),
            for (final material in value)
              ListTile(
                title: Text(material.nome),
                subtitle: Text(
                  '${material.precoReferencia.formatado}/'
                  '${material.unidade.simbolo}'
                  '${material.ativo ? '' : ' • inativo'}',
                ),
                onTap: () => context.push(AppRoutes.material(id: material.id)),
              ),
          ],
        ),
        AsyncError() => Center(
          child: Text(
            'Não foi possível carregar os materiais.',
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
