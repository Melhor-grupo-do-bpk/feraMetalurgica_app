import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/core/widgets/currency_field.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculo_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/custos_operacionais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um custo operacional: rótulo, ícone, leitura e escrita no modelo.
typedef _Custo = (
  String rotulo,
  IconData icone,
  double Function(CustosOperacionais) ler,
  CustosOperacionais Function(CustosOperacionais, double) escrever,
);

final List<_Custo> _custos = [
  (
    'Matéria-prima',
    Icons.inventory_2_outlined,
    (c) => c.materiaPrima,
    (c, v) => c.copyWith(materiaPrima: v),
  ),
  (
    'Mão de obra',
    Icons.engineering_outlined,
    (c) => c.maoDeObra,
    (c, v) => c.copyWith(maoDeObra: v),
  ),
  (
    'Insumos',
    Icons.handyman_outlined,
    (c) => c.insumos,
    (c, v) => c.copyWith(insumos: v),
  ),
  (
    'Combustível',
    Icons.local_gas_station_outlined,
    (c) => c.combustivel,
    (c, v) => c.copyWith(combustivel: v),
  ),
  (
    'Impostos',
    Icons.receipt_long_outlined,
    (c) => c.impostos,
    (c, v) => c.copyWith(impostos: v),
  ),
];

/// Etapa 3 do wizard (Tela 4): os 5 custos operacionais e o resumo com o
/// total previsto, atualizado enquanto se digita (RF-23). Única tela que
/// mostra custos internos (D-16).
class EtapaCustos extends ConsumerWidget {
  /// Cria a etapa ligada ao wizard de [provider].
  const EtapaCustos({required this.provider, super.key});

  /// Provider do wizard aberto.
  final OrcamentoWizardControllerProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final custos = ref
        .watch(provider)
        .requireValue!
        .orcamento
        .custosOperacionais;

    void alterar(
      CustosOperacionais Function(CustosOperacionais, double) escrever,
      double valor,
    ) {
      final atuais = ref
          .read(provider)
          .requireValue!
          .orcamento
          .custosOperacionais;
      ref.read(provider.notifier).atualizarCustos(escrever(atuais, valor));
    }

    final valor = AppTextStyles.body.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final rotulo = AppTextStyles.body.copyWith(color: colors.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (nome, icone, ler, escrever) in _custos) ...[
          SectionCard(
            titulo: nome,
            icone: icone,
            child: CurrencyField(
              key: Key('custo-$nome'),
              valorInicial: ler(custos),
              onChanged: (v) => alterar(escrever, v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Resumo de Custos',
                style: AppTextStyles.headline.copyWith(
                  color: colors.brandStrong,
                ),
              ),
              Divider(height: AppSpacing.lg, color: colors.borderSubtle),
              for (final (nome, _, ler, _) in _custos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Expanded(child: Text(nome, style: rotulo)),
                      Text(formatarMoeda(ler(custos)), style: valor),
                    ],
                  ),
                ),
              Divider(height: AppSpacing.lg, color: colors.borderSubtle),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Tot. Previsto', style: rotulo),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerRight,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatarMoeda(calcularTotalCustos(custos)),
                        key: const Key('total-previsto'),
                        style: AppTextStyles.amount.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
