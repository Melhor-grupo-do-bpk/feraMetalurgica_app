import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_peca.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/menu_acoes_linha.dart';
import 'package:flutter/material.dart' hide Material;

/// Uma peça já aceita no produto em montagem: descrição, material,
/// medidas e o custo da linha (da `CalculadoraOrcamento`).
class PecaLinha extends StatelessWidget {
  /// Cria a linha.
  const PecaLinha({
    required this.peca,
    required this.resultado,
    required this.emEdicao,
    required this.onAcao,
    super.key,
  });

  /// A peça.
  final PecaOrcamento peca;

  /// O cálculo da peça.
  final ResultadoPeca resultado;

  /// Se está carregada no formulário da peça.
  final bool emEdicao;

  /// Ação do menu; `null` desabilita o menu.
  final ValueChanged<AcaoLinha>? onAcao;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final material = peca.material;
    final simbolo = material.unidade.simbolo;
    final medidas = [
      peca.comprimentoCm,
      peca.larguraCm,
      ?peca.espessuraCm,
    ].map((m) => m.formatada).join(' × ');
    final secundario = AppTextStyles.caption.copyWith(
      color: colors.textSecondary,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: emEdicao ? colors.primary : colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${peca.quantidadePorProduto} × ${peca.descricao}'
                  '${emEdicao ? ' (em edição)' : ''}',
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${material.nome}, ${material.precoAplicado.formatado}/'
                  '$simbolo${material.precoAjustado ? ' (ajustado)' : ''}',
                  style: secundario,
                ),
                Text('$medidas cm', style: secundario),
                Text(
                  'Custo da linha: ${resultado.custoLinha.formatado}',
                  style: AppTextStyles.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          MenuAcoesLinha(
            tooltip: 'Ações da peça ${peca.descricao}',
            onSelecionar: onAcao,
          ),
        ],
      ),
    );
  }
}
