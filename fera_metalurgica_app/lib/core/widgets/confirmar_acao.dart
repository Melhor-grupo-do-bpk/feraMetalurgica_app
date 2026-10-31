import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Pede confirmação de uma ação destrutiva (descartar o orçamento, excluir
/// um item, inativar um material, excluir uma tarefa). Retorna `true` só se
/// o usuário tocar em [acao], que aparece na cor de erro; tocar fora ou em
/// "Cancelar" mantém tudo.
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String acao,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
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
          child: Text(acao),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
