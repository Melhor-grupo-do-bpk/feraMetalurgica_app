import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 4, prévia. Stub da F2: emitente, cliente, produtos e o total geral
/// da sessão; na edição, o código e a próxima revisão (D-30).
// TODO(V2-B): prévia comercial como widget separado, alimentado só pelos
// dados do orçamento, para o PDF reaproveitar (prompt §4).
class EtapaPrevia extends ConsumerWidget {
  /// Cria a etapa.
  const EtapaPrevia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final estado = ref.watch(orcamentoControllerProvider);
    final edicao = estado.edicao;
    if (edicao == null) return const SizedBox.shrink();
    final estilo = AppTextStyles.body.copyWith(color: colors.textPrimary);
    final revisao = edicao.revisao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (edicao.codigo case final codigo?)
          Text(
            'Orçamento $codigo rev. ${(revisao ?? 1) + 1}',
            style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
          ),
        Text('Emitente: ${edicao.emitente.nomeRazaoSocial}', style: estilo),
        Text('Cliente: ${edicao.cliente?.nome ?? '—'}', style: estilo),
        const SizedBox(height: AppSpacing.sm),
        for (final item in edicao.itens)
          Text('${item.quantidadeProdutos} × ${item.descricao}', style: estilo),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Total geral: ${estado.resumo?.totalGeral.formatado ?? '—'}',
          style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}
