import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefas_atrasadas.dart';
import 'package:flutter/material.dart';

/// Aviso no topo da agenda (v2-plano §6, item 7): "N tarefas atrasadas" e
/// o atalho "Ver", que abre a lista delas.
class AvisoAtrasadas extends StatelessWidget {
  /// Cria o aviso para [quantidade] tarefas atrasadas.
  const AvisoAtrasadas({
    required this.quantidade,
    required this.onVer,
    super.key,
  });

  /// Quantidade de tarefas atrasadas (maior que zero).
  final int quantidade;

  /// Toque em "Ver".
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const ValueKey('aviso-atrasadas'),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.dangerContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.onDangerContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              contarAtrasadas(quantidade),
              style: AppTextStyles.bodyStrong.copyWith(
                color: colors.onDangerContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onVer,
            style: TextButton.styleFrom(
              foregroundColor: colors.onDangerContainer,
              textStyle: AppTextStyles.labelStrong,
              minimumSize: const Size(48, 48),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}
