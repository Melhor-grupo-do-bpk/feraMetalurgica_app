import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_ui.dart';
import 'package:flutter/material.dart' as flutter show Material;
import 'package:flutter/material.dart' hide Material;

/// Ações do menu de um material na lista.
enum AcaoMaterial {
  /// Abre o formulário.
  editar,

  /// Inativa o ativo ou reativa o inativo.
  alternarSituacao,
}

/// Cartão de um material na lista: nome, preço de referência por unidade e
/// a situação, com o menu Editar / Inativar ou Reativar.
class MaterialCard extends StatelessWidget {
  /// Cria o cartão de [material].
  const MaterialCard({
    required this.material,
    required this.onTap,
    required this.onAcao,
    super.key,
  });

  /// Material exibido.
  final Material material;

  /// Ação ao tocar no cartão (editar).
  final VoidCallback onTap;

  /// Chamado com a ação escolhida no menu.
  final ValueChanged<AcaoMaterial> onAcao;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return flutter.Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.nome,
                      style: AppTextStyles.title.copyWith(
                        color: material.ativo
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${material.precoReferencia.formatado}'
                          '/${material.unidade.simbolo}',
                          style: AppTextStyles.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (!material.ativo) const StatusChip(label: 'Inativo'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<AcaoMaterial>(
                tooltip: 'Ações do material ${material.nome}',
                icon: const Icon(Icons.more_vert),
                onSelected: onAcao,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: AcaoMaterial.editar,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: AcaoMaterial.alternarSituacao,
                    child: Text(material.ativo ? 'Inativar' : 'Reativar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
