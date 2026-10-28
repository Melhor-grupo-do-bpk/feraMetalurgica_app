import 'dart:io';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Foto 16:9 de um produto do catálogo (D-18): `Image.asset` quando
/// [fotoPath] começa com `assets/`, `Image.file` nos demais casos e um
/// placeholder com ícone quando não há foto ou ela não carrega.
class ProdutoFoto extends StatelessWidget {
  /// Cria a foto de [fotoPath].
  const ProdutoFoto({required this.fotoPath, super.key});

  /// Caminho da foto (`ProdutoCatalogo.fotoPath`).
  final String? fotoPath;

  @override
  Widget build(BuildContext context) {
    final path = fotoPath;
    Widget erro(BuildContext context, Object error, StackTrace? stack) =>
        const _Placeholder();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: switch (path) {
        null || '' => const _Placeholder(),
        _ when path.startsWith('assets/') => Image.asset(
          path,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: erro,
        ),
        _ => Image.file(
          File(path),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: erro,
        ),
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      key: const ValueKey('produto-foto-placeholder'),
      color: colors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: colors.textMuted,
          semanticLabel: 'Sem foto',
        ),
      ),
    );
  }
}
