import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/detalhes/detalhes_cliente_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/detalhes/detalhes_itens_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/detalhes/valor_final_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalhes de um orçamento (Tela 6), aberta em tela cheia.
class OrcamentoDetalhesPage extends ConsumerWidget {
  /// Cria a tela do orçamento [orcamentoId].
  const OrcamentoDetalhesPage({required this.orcamentoId, super.key});

  /// Identificador do orçamento exibido.
  final String orcamentoId;

  /// Envia o resumo do orçamento pelo WhatsApp do cliente (RF-34, D-15).
  Future<void> _enviarWhatsApp(
    BuildContext context,
    WidgetRef ref,
    Orcamento orcamento,
  ) async {
    final abriu = await ref
        .read(whatsappLauncherProvider)
        .abrirWhatsApp(
          orcamento.cliente.numero,
          montarMensagemWhatsApp(orcamento),
        );
    if (!abriu) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o WhatsApp. Confira o número do cliente.',
          ),
        ),
      );
      return;
    }
    // Só sai de emAnalise; os outros status não mudam ao reenviar (D-06).
    if (orcamento.status == StatusOrcamento.emAnalise) {
      await ref
          .read(orcamentosProvider.notifier)
          .salvar(orcamento.copyWith(status: StatusOrcamento.enviado));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: switch (ref.watch(orcamentoPorIdProvider(orcamentoId))) {
        AsyncData(value: null) => const _NaoEncontrado(),
        AsyncData(value: final Orcamento orcamento) => _Conteudo(
          orcamento: orcamento,
          onEnviarWhatsApp: () => _enviarWhatsApp(context, ref, orcamento),
        ),
        AsyncError() => _Erro(
          onTentarNovamente: () => ref.invalidate(orcamentosProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Conteudo extends ConsumerWidget {
  const _Conteudo({required this.orcamento, required this.onEnviarWhatsApp});

  final Orcamento orcamento;
  final VoidCallback onEnviarWhatsApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DetalhesClienteCard(
          orcamento: orcamento,
          onAlterarStatus: (status) => ref
              .read(orcamentosProvider.notifier)
              .salvar(orcamento.copyWith(status: status)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DetalhesItensCard(itens: orcamento.itens),
        const SizedBox(height: AppSpacing.lg),
        ValorFinalCard(
          valorFinal: orcamento.valorFinal,
          onEnviarWhatsApp: onEnviarWhatsApp,
          onGerarPdf: () => context.push(AppRoutes.pdfOrcamento(orcamento.id)),
          onEditar: () => context.push(AppRoutes.editarOrcamento(orcamento.id)),
        ),
      ],
    );
  }
}

class _NaoEncontrado extends StatelessWidget {
  const _NaoEncontrado();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Orçamento não encontrado',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedAppButton(
              label: 'Voltar',
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.onTentarNovamente});

  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Não foi possível carregar o orçamento.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedAppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              onPressed: onTentarNovamente,
            ),
          ],
        ),
      ),
    );
  }
}
