import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/confirmar_acao.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/detalhes/acoes_orcamento_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/detalhes/detalhes_status_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/excluir_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/previa_orcamento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalhes de um orçamento salvo (Tela 6), aberta em tela cheia: status,
/// a [PreviaOrcamento] com os totais gravados (D-39, sem recalcular), as
/// ações e as tarefas da agenda vinculadas.
class OrcamentoDetalhesPage extends ConsumerWidget {
  /// Cria a tela do orçamento [orcamentoId].
  const OrcamentoDetalhesPage({required this.orcamentoId, super.key});

  /// Identificador do orçamento exibido.
  final String orcamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: switch (ref.watch(orcamentoPorIdProvider(orcamentoId))) {
        AsyncData(value: null) => const _NaoEncontrado(),
        AsyncData(value: final Orcamento orcamento) => _Conteudo(
          orcamento: orcamento,
        ),
        AsyncError() => _Erro(
          onTentarNovamente: () => ref.invalidate(orcamentosProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Conteudo extends ConsumerStatefulWidget {
  const _Conteudo({required this.orcamento});

  final Orcamento orcamento;

  @override
  ConsumerState<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends ConsumerState<_Conteudo> {
  // Os detalhes podem ser mostrados ao cliente: os custos das peças só
  // aparecem quando o operador liga, como na etapa 4.
  bool _mostrarPecas = false;

  Orcamento get _orcamento => widget.orcamento;

  // Gerar o PDF leva um instante: um segundo toque não abre outro envio.
  bool _enviando = false;

  /// Envia o PDF pelo WhatsApp do cliente (RF-34, D-43). Abrir o WhatsApp ou
  /// o compartilhamento marca como enviado (D-29); reenviar mantém o
  /// `enviadoEm`.
  Future<void> _enviarWhatsApp() async {
    if (_enviando) return;
    _enviando = true;
    try {
      final abriu = await ref
          .read(whatsappLauncherProvider)
          .enviarOrcamento(_orcamento);
      if (!abriu) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar o PDF.')),
        );
        return;
      }
      await ref
          .read(orcamentosProvider.notifier)
          .alterarStatus(_orcamento.id, StatusOrcamento.enviado);
    } finally {
      _enviando = false;
    }
  }

  /// De criado para enviado, direto. De enviado para criado, confirma
  /// antes, porque o `enviadoEm` é apagado e o orçamento sai dos cards de
  /// envio do mês (D-37).
  Future<void> _alternarStatus() async {
    final orcamentos = ref.read(orcamentosProvider.notifier);
    if (_orcamento.status == StatusOrcamento.criado) {
      await orcamentos.alterarStatus(_orcamento.id, StatusOrcamento.enviado);
      return;
    }
    final enviadoEm = _orcamento.enviadoEm;
    final voltar = await confirmarAcao(
      context,
      titulo: 'Voltar para criado?',
      mensagem:
          'O orçamento perde a data de envio'
          '${enviadoEm == null ? '' : ' (${formatarData(enviadoEm)})'} e '
          'sai dos cards de envio do mês no Início.',
      acao: 'Voltar para criado',
    );
    if (!voltar) return;
    await orcamentos.alterarStatus(_orcamento.id, StatusOrcamento.criado);
  }

  /// Exclui depois de confirmar e volta à tela anterior.
  Future<void> _excluir() => excluirOrcamento(
    context,
    _orcamento,
    aoConfirmar: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.orcamentos);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        DetalhesStatusCard(
          orcamento: _orcamento,
          onAlternarStatus: _alternarStatus,
          onExcluir: _excluir,
        ),
        const SizedBox(height: AppSpacing.xs),
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
        PreviaOrcamento.deOrcamento(_orcamento, mostrarPecas: _mostrarPecas),
        const SizedBox(height: AppSpacing.lg),
        AcoesOrcamentoCard(
          onEnviarWhatsApp: _enviarWhatsApp,
          onGerarPdf: () => context.push(AppRoutes.pdfOrcamento(_orcamento.id)),
          onEditar: () =>
              context.push(AppRoutes.editarOrcamento(_orcamento.id)),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Widgets da agenda (V2-E), só posicionados aqui.
        SectionCard(
          titulo: 'Agenda',
          icone: Icons.event_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TarefasDoOrcamento(orcamentoId: _orcamento.id),
              const SizedBox(height: AppSpacing.sm),
              AgendarTarefaButton(orcamentoId: _orcamento.id),
            ],
          ),
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
