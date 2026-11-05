import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/previa_orcamento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 4, prévia (prompt §4): a [PreviaOrcamento] da sessão, com o
/// resumo do controller. O detalhe das peças (uso interno) abre por um
/// interruptor; voltar para corrigir é pelo rodapé do wizard.
class EtapaPrevia extends ConsumerStatefulWidget {
  /// Cria a etapa.
  const EtapaPrevia({super.key});

  @override
  ConsumerState<EtapaPrevia> createState() => _EtapaPreviaState();
}

class _EtapaPreviaState extends ConsumerState<EtapaPrevia> {
  bool _mostrarPecas = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final estado = ref.watch(orcamentoControllerProvider);
    final edicao = estado.edicao;
    final resumo = estado.resumo;
    // Só chega aqui com cliente e itens válidos (o avançar valida); a
    // mensagem cobre um estado inesperado sem quebrar a tela.
    if (edicao == null || edicao.cliente == null || resumo == null) {
      return Text(
        'Volte às etapas anteriores e confira os dados.',
        style: AppTextStyles.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _mostrarPecas,
          onChanged: (valor) => setState(() => _mostrarPecas = valor),
          title: Text(
            'Mostrar peças e custos',
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
          ),
          subtitle: Text(
            'Uso interno: não vai para o documento do cliente.',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        PreviaOrcamento.daEdicao(
          edicao,
          resumo: resumo,
          agora: ref.watch(agoraProvider),
          mostrarPecas: _mostrarPecas,
        ),
      ],
    );
  }
}
