import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/lista/alternar_situacao_material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/lista/materiais_lista_filtro.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/lista/material_card.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lista de materiais, aberta por "Mais" (D-31): busca por nome, filtro
/// Ativos/Todos, e acesso a criar, editar, inativar e reativar (prompt
/// §3.1). Materiais não são excluídos.
class MateriaisPage extends ConsumerWidget {
  /// Cria a tela.
  const MateriaisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filtro = ref.watch(materiaisListaFiltroProvider);
    final notifier = ref.read(materiaisListaFiltroProvider.notifier);
    final todos = ref.watch(materiaisProvider);
    final filtrados = ref.watch(materiaisListaFiltradosProvider);

    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Materiais',
                        style: AppTextStyles.headline.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const _BotaoNovo(),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const ValueKey('materiais-busca'),
                  onChanged: notifier.buscar,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar material...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilterChipsBar(
                  opcoes: const ['Ativos', 'Todos'],
                  selecionado: filtro.somenteAtivos ? 0 : 1,
                  onSelecionado: (i) =>
                      notifier.filtrarSomenteAtivos(somenteAtivos: i == 0),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (filtrados) {
              AsyncData(:final value) when value.isEmpty => _Vazio(
                semCadastro: todos.value?.isEmpty ?? true,
              ),
              AsyncData(:final value) => _Lista(materiais: value),
              AsyncError() => _Erro(
                onTentarNovamente: () => ref.invalidate(materiaisProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Abre o formulário de um material novo e avisa quando ele volta salvo.
Future<void> _novoMaterial(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final id = await context.push<String>(AppRoutes.material());
  if (id == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Material salvo.')));
}

class _BotaoNovo extends StatelessWidget {
  const _BotaoNovo();

  @override
  Widget build(BuildContext context) => DarkButton(
    label: 'Novo',
    icon: Icons.add,
    onPressed: () => _novoMaterial(context),
  );
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.materiais});

  final List<Material> materiais;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: materiais.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final material = materiais[i];
        void editar() => context.push(AppRoutes.material(id: material.id));
        return MaterialCard(
          key: ValueKey('material-${material.id}'),
          material: material,
          onTap: editar,
          onAcao: (acao) => switch (acao) {
            AcaoMaterial.editar => editar(),
            AcaoMaterial.alternarSituacao => alternarSituacaoMaterial(
              context,
              ref,
              material,
            ),
          },
        );
      },
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.semCadastro});

  /// Nenhum material cadastrado (e não só nenhum que passe no filtro).
  final bool semCadastro;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 48, color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              semCadastro
                  ? 'Nenhum material cadastrado'
                  : 'Nenhum material encontrado',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            if (semCadastro) ...[
              const SizedBox(height: AppSpacing.md),
              const _BotaoNovo(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.onTentarNovamente});

  final VoidCallback onTentarNovamente;

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
              'Não foi possível carregar os materiais.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedAppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              onPressed: onTentarNovamente,
            ),
          ],
        ),
      ),
    );
  }
}
