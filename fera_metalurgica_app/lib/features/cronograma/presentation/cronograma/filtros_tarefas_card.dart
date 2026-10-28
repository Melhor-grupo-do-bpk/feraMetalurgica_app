import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_ui.dart';
import 'package:flutter/material.dart';

/// Card "Filtros de tarefas" (RF-81, D-05): uma caixa por [TipoTarefa].
class FiltrosTarefasCard extends StatelessWidget {
  /// Cria o card.
  const FiltrosTarefasCard({
    required this.marcados,
    required this.onAlterado,
    super.key,
  });

  /// Tipos marcados.
  final Set<TipoTarefa> marcados;

  /// Toque numa caixa: o tipo e o novo valor.
  final void Function(TipoTarefa tipo, {required bool marcado}) onAlterado;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SectionCard(
      titulo: 'Filtros de tarefas',
      // O fundo do card é um `DecoratedBox`: o `Material` transparente faz o
      // efeito de toque do `CheckboxListTile` aparecer por cima dele.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final tipo in TipoTarefa.values)
              CheckboxListTile(
                value: marcados.contains(tipo),
                onChanged: (valor) => onAlterado(tipo, marcado: valor ?? false),
                title: Text(
                  tipo.labelFiltro,
                  style: AppTextStyles.body.copyWith(color: colors.textPrimary),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: colors.darkSurface,
                checkColor: colors.onDarkSurface,
              ),
          ],
        ),
      ),
    );
  }
}
