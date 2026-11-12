import 'dart:async';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/theme/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top bar padrão das telas: voltar (opcional), logo FERA e a troca de
/// tema claro/escuro (D-45).
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Cria a top bar. O botão voltar só aparece quando [onBack] é informado.
  const AppTopBar({this.onBack, super.key});

  /// Ação do botão voltar; `null` esconde o botão.
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.topBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppSpacing.topBarHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const AppLogo(),
              if (onBack != null)
                Positioned(
                  left: AppSpacing.xs,
                  child: IconButton(
                    tooltip: 'Voltar',
                    icon: const Icon(Icons.arrow_back),
                    color: colors.textPrimary,
                    onPressed: onBack,
                  ),
                ),
              Positioned(
                right: AppSpacing.xs,
                child: IconButton(
                  tooltip: escuro ? 'Usar tema claro' : 'Usar tema escuro',
                  icon: Icon(
                    escuro
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  color: colors.textPrimary,
                  onPressed: () => unawaited(
                    ref
                        .read(temaAppProvider.notifier)
                        .alternar(atual: Theme.of(context).brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo FERA: marca "F" + wordmark "ERA." (o ponto usa a cor da marca).
class AppLogo extends StatelessWidget {
  /// Cria o logo.
  const AppLogo({super.key});

  /// Caminho do asset da marca "F".
  static const String assetPath = 'assets/images/logo_fera.png';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'FERA',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 25, height: 25),
          Text.rich(
            TextSpan(
              text: 'ERA',
              children: [
                TextSpan(
                  text: '.',
                  style: TextStyle(color: colors.brand),
                ),
              ],
            ),
            style: AppTextStyles.logo.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
