import 'package:fera_metalurgica_app/core/widgets/confirmar_acao.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inativa [material] (com confirmação) ou o reativa, e avisa o resultado.
/// Usado na lista e no formulário. Materiais não são excluídos: o inativo
/// só some das novas seleções (prompt §3.1).
Future<void> alternarSituacaoMaterial(
  BuildContext context,
  WidgetRef ref,
  Material material,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(materiaisProvider.notifier);
  if (material.ativo) {
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Inativar material?',
      mensagem:
          '"${material.nome}" deixa de aparecer nas novas peças. Os '
          'orçamentos que já o usam não mudam, e você pode reativá-lo '
          'depois.',
      acao: 'Inativar',
    );
    if (!confirmado) return;
  }
  void avisar(String mensagem) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
  try {
    if (material.ativo) {
      await notifier.inativar(material.id);
      avisar('Material inativado.');
    } else {
      await notifier.reativar(material.id);
      avisar('Material reativado.');
    }
  } on Object {
    avisar('Não foi possível alterar a situação do material.');
  }
}
