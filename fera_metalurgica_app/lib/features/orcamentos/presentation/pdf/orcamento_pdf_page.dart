import 'dart:typed_data';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/pdf/orcamento_pdf_builder.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/pdf/previa_pdf_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Prévia do PDF de um orçamento (Tela 7, RF-40 a RF-42), aberta em tela
/// cheia. "Baixar" abre o compartilhamento do sistema com o arquivo.
class OrcamentoPdfPage extends ConsumerWidget {
  /// Cria a prévia do orçamento [orcamentoId].
  const OrcamentoPdfPage({required this.orcamentoId, super.key});

  /// Identificador do orçamento.
  final String orcamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: switch (ref.watch(orcamentoPorIdProvider(orcamentoId))) {
        AsyncData(value: null) => _Mensagem(
          texto: 'Orçamento não encontrado',
          rotuloAcao: 'Voltar',
          icone: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
        AsyncData(value: final Orcamento orcamento) => _Previa(
          orcamento: orcamento,
        ),
        AsyncError() => _Mensagem(
          texto: 'Não foi possível carregar o orçamento.',
          rotuloAcao: 'Tentar novamente',
          icone: Icons.refresh,
          onPressed: () => ref.invalidate(orcamentosProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Previa extends ConsumerStatefulWidget {
  const _Previa({required this.orcamento});

  final Orcamento orcamento;

  @override
  ConsumerState<_Previa> createState() => _PreviaState();
}

class _PreviaState extends ConsumerState<_Previa> {
  // O PDF é gerado uma vez por orçamento e reaproveitado pela prévia e pelo
  // "Baixar"; um `build` novo a cada rebuild faria o `PdfPreview` redesenhar.
  Future<Uint8List>? _pdfGerado;
  late LayoutCallback _gerar;

  Future<Uint8List> get _pdf =>
      _pdfGerado ??= gerarOrcamentoPdf(widget.orcamento);

  @override
  void initState() {
    super.initState();
    _gerar = (_) => _pdf;
  }

  @override
  void didUpdateWidget(_Previa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orcamento != widget.orcamento) {
      _pdfGerado = null;
      _gerar = (_) => _pdf;
    }
  }

  Future<void> _baixar() async {
    try {
      await Printing.sharePdf(
        bytes: await _pdf,
        filename: 'orcamento-${widget.orcamento.id}.pdf',
      );
    } on Exception catch (erro) {
      debugPrint('Falha ao compartilhar o PDF: $erro');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível compartilhar o PDF.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: switch (ref.watch(previaPdfDisponivelProvider)) {
            AsyncData(value: true) => PdfPreview(
              build: _gerar,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: 'orcamento-${widget.orcamento.id}.pdf',
              useActions: false,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              scrollViewDecoration: BoxDecoration(color: colors.background),
              onError: (context, _) => const _Mensagem(
                texto: 'Não foi possível mostrar a prévia do PDF.',
              ),
            ),
            AsyncData() || AsyncError() => const _Mensagem(
              texto:
                  'A prévia não está disponível neste aparelho. '
                  'Toque em "Baixar" para abrir o PDF.',
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
        _Rodape(onBaixar: _baixar),
      ],
    );
  }
}

/// Rodapé da Tela 7: "Voltar" à esquerda e "Baixar" à direita.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.onBaixar});

  final VoidCallback onBaixar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  minimumSize: const Size(48, 48),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Baixar',
                trailingIcon: Icons.download,
                onPressed: onBaixar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto centralizado com uma ação opcional (não encontrado, erro).
class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.texto,
    this.rotuloAcao,
    this.icone,
    this.onPressed,
  });

  final String texto;
  final String? rotuloAcao;
  final IconData? icone;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rotulo = rotuloAcao;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            if (rotulo != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedAppButton(
                label: rotulo,
                icon: icone,
                onPressed: onPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
