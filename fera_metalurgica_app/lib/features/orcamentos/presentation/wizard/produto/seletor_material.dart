import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Abre a lista de materiais ativos (prompt §3.1: inativos não aparecem em
/// novas seleções) e devolve o escolhido, ou `null` se o operador fechar.
///
/// O atalho "Cadastrar material" abre o formulário de material
/// (`AppRoutes.material()`, que devolve o id ao salvar) e devolve o
/// material recém-cadastrado.
Future<Material?> escolherMaterial(BuildContext context, WidgetRef ref) async {
  final escolha = await showModalBottomSheet<_Escolha>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SeletorMaterial(),
  );
  switch (escolha) {
    case null:
      return null;
    case _Escolhido(:final material):
      return material;
    case _Cadastrar():
      if (!context.mounted) return null;
      final id = await context.push<String>(AppRoutes.material());
      if (id == null) return null;
      // O `materiaisProvider` já foi recarregado pelo formulário ao salvar.
      final materiais = await ref.read(materiaisProvider.future);
      return materiais.where((m) => m.id == id && m.ativo).firstOrNull;
  }
}

sealed class _Escolha {
  const _Escolha();
}

class _Escolhido extends _Escolha {
  const _Escolhido(this.material);

  final Material material;
}

class _Cadastrar extends _Escolha {
  const _Cadastrar();
}

class _SeletorMaterial extends ConsumerWidget {
  const _SeletorMaterial();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final materiais = ref.watch(materiaisAtivosProvider);
    final cadastrar = ListTile(
      leading: Icon(Icons.add, color: colors.primary),
      title: Text(
        'Cadastrar material',
        style: AppTextStyles.bodyStrong.copyWith(color: colors.primary),
      ),
      onTap: () => Navigator.of(context).pop(const _Cadastrar()),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Escolher material',
                style: AppTextStyles.title.copyWith(color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: switch (materiais) {
                AsyncData(value: final lista) when lista.isEmpty => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Nenhum material ativo. Cadastre um para continuar.',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                AsyncData(value: final lista) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final material in lista)
                      ListTile(
                        title: Text(
                          material.nome,
                          style: AppTextStyles.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${material.precoReferencia.formatado}/'
                          '${material.unidade.simbolo}',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        onTap: () =>
                            Navigator.of(context).pop(_Escolhido(material)),
                      ),
                  ],
                ),
                AsyncError() => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Não foi possível carregar os materiais.',
                        style: AppTextStyles.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(materiaisProvider),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
            const Divider(height: 1),
            cadastrar,
          ],
        ),
      ),
    );
  }
}
