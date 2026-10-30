import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/aviso_inline.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/linha_resumo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/menu_acoes_linha.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/produto_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/produto_form.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/rascunho_produto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_dialogos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 2, produtos (prompt §4): a lista de produtos do orçamento, com o
/// subtotal de cada um e o total dos produtos, e o formulário do produto
/// com a composição de peças.
///
/// Os números vêm da `CalculadoraOrcamento`. O produto em montagem fica no
/// `rascunhoProdutoProvider` e só entra na sessão (pelo
/// `OrcamentoController`) com pelo menos uma peça.
class EtapaProdutos extends ConsumerWidget {
  /// Cria a etapa.
  const EtapaProdutos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final itens =
        ref.watch(orcamentoControllerProvider).edicao?.itens ??
        const <ItemOrcamento>[];
    final rascunho = ref.watch(rascunhoProdutoProvider);
    // Só os produtos, sem os adicionais: o total da etapa 2 não depende da
    // etapa 3 estar válida.
    final resultado = const CalculadoraOrcamento().calcularOrcamento(
      itens: itens,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rascunho != null && rascunho.alterado) ...[
          AvisoInline(
            texto: rascunho.ehEdicao
                ? 'As alterações do produto ainda não foram salvas. Salve '
                      'ou cancele antes de continuar.'
                : 'Há um produto em montagem que ainda não foi adicionado. '
                      'Adicione ou cancele antes de continuar.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (itens.isEmpty && rascunho == null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Nenhum produto adicionado. Cada produto tem um preço base e '
              'as peças que o compõem.',
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
          ),
        for (final (i, item) in itens.indexed)
          ProdutoCard(
            key: ValueKey('produto-${item.id}'),
            numero: i + 1,
            item: item,
            resultado: resultado.itens[i],
            onAcao: rascunho == null
                ? (acao) => _acaoProduto(context, ref, acao, item)
                : null,
          ),
        if (itens.isNotEmpty) ...[
          LinhaResumo(
            rotulo: 'Total dos produtos',
            valor: resultado.totalProdutos.formatado,
            destaque: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (rascunho == null)
          OutlinedAppButton(
            label: itens.isEmpty ? 'Adicionar produto' : 'Novo produto',
            icon: Icons.add,
            onPressed: ref.read(rascunhoProdutoProvider.notifier).abrirNovo,
          )
        else
          ProdutoForm(key: ValueKey('produto-form-${rascunho.origem.id}')),
      ],
    );
  }

  Future<void> _acaoProduto(
    BuildContext context,
    WidgetRef ref,
    AcaoLinha acao,
    ItemOrcamento item,
  ) async {
    final controller = ref.read(orcamentoControllerProvider.notifier);
    switch (acao) {
      case AcaoLinha.editar:
        ref.read(rascunhoProdutoProvider.notifier).abrirEdicao(item);
      case AcaoLinha.duplicar:
        controller.duplicarItem(item.id);
      case AcaoLinha.remover:
        final remover = await confirmarAcao(
          context,
          titulo: 'Remover o produto?',
          mensagem: '"${item.descricao}" e as peças dele saem do orçamento.',
          acao: 'Remover',
        );
        if (remover) controller.removerItem(item.id);
    }
  }
}
