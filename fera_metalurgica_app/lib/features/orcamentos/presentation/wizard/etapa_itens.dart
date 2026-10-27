import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/item_card.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/item_form.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_campo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_dialogos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 2 do wizard (Tela 3): nome do projeto (D-02), formulário de item
/// e lista dos itens adicionados (RF-22).
class EtapaItens extends ConsumerStatefulWidget {
  /// Cria a etapa ligada ao wizard de [provider].
  const EtapaItens({required this.provider, super.key});

  /// Provider do wizard aberto.
  final OrcamentoWizardControllerProvider provider;

  @override
  ConsumerState<EtapaItens> createState() => _EtapaItensState();
}

class _EtapaItensState extends ConsumerState<EtapaItens> {
  late final TextEditingController _projeto = TextEditingController(
    text: ref.read(widget.provider).requireValue!.orcamento.projeto,
  );

  /// Item carregado no formulário, ou `null` ao adicionar um novo.
  ItemOrcamento? _emEdicao;

  /// Muda a cada item adicionado, para recriar (limpar) o formulário.
  int _formularios = 0;

  @override
  void dispose() {
    _projeto.dispose();
    super.dispose();
  }

  void _salvarItem(ItemOrcamento item) {
    final wizard = ref.read(widget.provider.notifier);
    if (_emEdicao == null) {
      wizard.adicionarItem(item);
    } else {
      wizard.atualizarItem(item);
    }
    setState(() {
      _emEdicao = null;
      _formularios++;
    });
  }

  Future<void> _excluirItem(ItemOrcamento item) async {
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Excluir item?',
      mensagem: '"${item.tipoServico}" será removido do orçamento.',
      acao: 'Excluir',
    );
    if (!confirmado || !mounted) return;
    ref.read(widget.provider.notifier).removerItem(item.id);
    if (_emEdicao?.id == item.id) {
      setState(() {
        _emEdicao = null;
        _formularios++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final itens = ref.watch(widget.provider).requireValue!.orcamento.itens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: WizardCampo(
            rotulo: 'Nome do projeto',
            child: TextField(
              key: const Key('campo-projeto'),
              controller: _projeto,
              textCapitalization: TextCapitalization.sentences,
              // Opcional: vazio vira o tipo do 1º item no concluir (D-02).
              decoration: const InputDecoration(
                hintText: 'Ex: Portão metálico',
              ),
              onChanged: ref.read(widget.provider.notifier).atualizarProjeto,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: ItemForm(
            key: ValueKey(_emEdicao?.id ?? 'novo-$_formularios'),
            item: _emEdicao,
            onSalvar: _salvarItem,
            onCancelar: () => setState(() {
              _emEdicao = null;
              _formularios++;
            }),
          ),
        ),
        if (itens.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Itens Adicionados (${itens.length})',
            style: AppTextStyles.title.copyWith(color: colors.textPrimary),
          ),
          for (final (i, item) in itens.indexed) ...[
            const SizedBox(height: AppSpacing.sm),
            ItemCard(
              rotulo: 'Item ${'${i + 1}'.padLeft(2, '0')}',
              titulo: item.tipoServico,
              detalhes: [
                if (item.medidas.formatada.isNotEmpty)
                  (Icons.straighten, item.medidas.formatada),
                if (item.materialPrincipal != null)
                  (Icons.layers_outlined, item.materialPrincipal!),
              ],
              rodape: 'Qtd: ${item.quantidade} un',
              onEditar: () => setState(() => _emEdicao = item),
              onExcluir: () => _excluirItem(item),
            ),
          ],
        ],
      ],
    );
  }
}
