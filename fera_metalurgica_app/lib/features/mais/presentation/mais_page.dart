import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Menu da aba "Mais" (D-13): atalhos para telas sem aba própria.
class MaisPage extends StatelessWidget {
  /// Cria a tela.
  const MaisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: const AppTopBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Mais',
            style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _MaisItem(
            icone: Icons.layers_outlined,
            titulo: 'Materiais',
            subtitulo: 'Materiais e preços de referência',
            onTap: () => context.push(AppRoutes.materiais),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MaisItem(
            icone: Icons.business_outlined,
            titulo: 'Dados da empresa',
            subtitulo: 'Emitente dos orçamentos',
            onTap: () => context.push(AppRoutes.empresa),
          ),
        ],
      ),
    );
  }
}

class _MaisItem extends StatelessWidget {
  const _MaisItem({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        leading: Icon(icone, color: colors.textPrimary),
        title: Text(
          titulo,
          style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
        ),
        subtitle: Text(
          subtitulo,
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
