import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
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
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar material?'),
        content: Text(
          '"${material.nome}" deixa de aparecer nas novas peças. Os '
          'orçamentos que já o usam não mudam, e você pode reativá-lo '
          'depois.',
        ),
        actions: [
          TextButton(
            // A cor primária sobre o fundo do diálogo não chega a 4,5:1
            // (D-25).
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
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
