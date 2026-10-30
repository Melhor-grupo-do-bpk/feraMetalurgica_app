import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 3, valores. Stub da F2: só mostra os valores da sessão e o total
/// geral calculado (não editável).
// TODO(V2-B): formulário de adicionais, desconto, validade e observações
// (prompt §4 e §6), por `atualizarValores`.
class EtapaValores extends ConsumerWidget {
  /// Cria a etapa.
  const EtapaValores({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final estado = ref.watch(orcamentoControllerProvider);
    final edicao = estado.edicao;
    if (edicao == null) return const SizedBox.shrink();
    final estilo = AppTextStyles.body.copyWith(color: colors.textPrimary);

    Widget linha(String rotulo, Dinheiro valor) =>
        Text('$rotulo: ${valor.formatado}', style: estilo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        linha('Insumos', edicao.insumos),
        linha('Impostos', edicao.impostos),
        linha('Combustível', edicao.combustivel),
        linha('Outros', edicao.outros),
        linha('Desconto', edicao.desconto),
        if (edicao.validadeDias case final dias?)
          Text('Validade: $dias dias', style: estilo),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Total geral: ${estado.resumo?.totalGeral.formatado ?? '—'}',
          style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}
