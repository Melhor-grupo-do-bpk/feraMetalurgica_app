import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 2, produtos. Stub da F2: lista os produtos da sessão com o total
/// calculado e permite remover; um botão provisório adiciona um produto de
/// teste, para o fluxo funcionar de ponta a ponta.
// TODO(V2-A): formulário de produto e composição de peças (prompt §4).
class EtapaProdutos extends ConsumerWidget {
  /// Cria a etapa.
  const EtapaProdutos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final estado = ref.watch(orcamentoControllerProvider);
    final itens = estado.edicao?.itens ?? const <ItemOrcamento>[];
    final resumo = estado.resumo;
    final materiais = ref.watch(materiaisAtivosProvider).value;
    final controller = ref.read(orcamentoControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (itens.isEmpty)
          Text(
            'Nenhum produto adicionado.',
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
        for (final (i, item) in itens.indexed)
          ListTile(
            title: Text(item.descricao),
            subtitle: Text(
              '${item.quantidadeProdutos} un • '
              '${resumo?.itens[i].totalItem.formatado ?? '—'}',
            ),
            trailing: IconButton(
              tooltip: 'Remover produto',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => controller.removerItem(item.id),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Total dos produtos: ${resumo?.totalProdutos.formatado ?? '—'}',
          style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        // TODO(V2-A): remover. Atalho da F2 para testar o fluxo sem o
        // formulário de produto.
        OutlinedAppButton(
          label: 'Adicionar produto de teste',
          icon: Icons.add,
          onPressed: () {
            final material = materiais?.firstOrNull;
            if (material == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cadastre um material ativo.')),
              );
              return;
            }
            controller.adicionarItem(_produtoDeTeste(material));
          },
        ),
      ],
    );
  }
}

/// Produto de teste com uma peça de [material], como o exemplo B do prompt
/// §9: 3 unidades, base R$ 150,00, peça de 120 × 60 cm (e 2 cm de
/// espessura, exigida em m³ e informativa em m²).
ItemOrcamento _produtoDeTeste(Material material) => ItemOrcamento(
  id: gerarId(),
  descricao: 'Produto de teste',
  quantidadeProdutos: 3,
  precoBase: Dinheiro.parse('150,00'),
  pecas: [
    PecaOrcamento(
      id: gerarId(),
      descricao: 'Peça de teste',
      quantidadePorProduto: 1,
      material: material.gerarSnapshot(),
      comprimentoCm: MedidaCm.parse('120'),
      larguraCm: MedidaCm.parse('60'),
      espessuraCm: MedidaCm.parse('2'),
    ),
  ],
);
