import 'package:flutter/material.dart';

/// Pede confirmação de uma ação destrutiva (descartar o orçamento, excluir
/// um item). Retorna `true` só se o usuário tocar em [acao].
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(acao),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
