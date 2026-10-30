import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/rascunho_produto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_dialogos.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se o wizard pode sair da etapa 2 (avançar ou voltar) sem perder um
/// produto em montagem (prompt §4: avisar quando há campos preenchidos e
/// não adicionados).
///
/// - Sem produto em montagem: `true`.
/// - Com o formulário aberto e intocado: fecha-o e devolve `true`.
/// - Com dados não adicionados: pede a confirmação do descarte; descarta e
///   devolve `true` só se o operador confirmar.
///
/// A `OrcamentoWizardPage` chama esta função antes de `avancar()` e de
/// `voltar()` na etapa 2 (HO-V2-A-01).
Future<bool> podeSairDaEtapaProdutos(
  BuildContext context,
  WidgetRef ref,
) async {
  final rascunho = ref.read(rascunhoProdutoProvider);
  if (rascunho == null) return true;
  final notifier = ref.read(rascunhoProdutoProvider.notifier);
  if (!rascunho.alterado) {
    notifier.descartar();
    return true;
  }
  final descartar = await confirmarAcao(
    context,
    titulo: rascunho.ehEdicao
        ? 'Alterações do produto não salvas'
        : 'Produto não adicionado',
    mensagem: rascunho.ehEdicao
        ? 'As alterações do produto em edição não foram salvas e serão '
              'perdidas.'
        : 'O produto em montagem não foi adicionado ao orçamento e será '
              'perdido.',
    acao: 'Descartar',
  );
  if (descartar) notifier.descartar();
  return descartar;
}
