import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/aviso_inline.dart';
import 'package:flutter/material.dart';

/// Destaque do total geral zero (prompt §6): é permitido, mas o operador
/// confere antes de salvar.
class AvisoTotalZero extends StatelessWidget {
  /// Cria o aviso.
  const AvisoTotalZero({super.key});

  @override
  Widget build(BuildContext context) => const AvisoInline(
    icone: Icons.warning_amber_rounded,
    texto: 'O total geral está zerado. Confira os valores antes de salvar.',
  );
}
