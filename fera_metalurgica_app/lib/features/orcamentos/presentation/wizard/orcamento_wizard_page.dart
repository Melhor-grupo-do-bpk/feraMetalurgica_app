import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/step_progress_bar.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_cliente.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_custos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_itens.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_resumo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_state.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_dialogos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const List<String> _subtitulos = [
  'Dados do cliente',
  'Detalhes do item(s)',
  'Custos Operacionais',
  'Resumo do orçamento',
];

/// Wizard de criação/edição de orçamento (Telas 2 a 5, RF-20 a RF-27).
class OrcamentoWizardPage extends ConsumerStatefulWidget {
  /// Cria o wizard. Com [orcamentoId], edita o orçamento existente; com
  /// [produtoId], começa um orçamento novo com esse produto do catálogo.
  const OrcamentoWizardPage({this.orcamentoId, this.produtoId, super.key});

  /// Orçamento em edição, ou `null` para um orçamento novo.
  final String? orcamentoId;

  /// Produto do catálogo que vira o primeiro item (RF-27), se houver.
  final String? produtoId;

  @override
  ConsumerState<OrcamentoWizardPage> createState() =>
      _OrcamentoWizardPageState();
}

class _OrcamentoWizardPageState extends ConsumerState<OrcamentoWizardPage> {
  final _formCliente = GlobalKey<FormState>();
  bool _salvando = false;

  OrcamentoWizardControllerProvider get _provider =>
      orcamentoWizardControllerProvider(
        orcamentoId: widget.orcamentoId,
        produtoId: widget.produtoId,
      );

  /// Voltar da top bar e do sistema: volta uma etapa; na etapa 1, sai do
  /// wizard, pedindo confirmação se algo mudou (D-07).
  Future<void> _voltar() async {
    if (ref.read(_provider.notifier).voltar()) return;
    final estado = ref.read(_provider).value;
    if (estado != null && estado.alterado) {
      final descartar = await confirmarAcao(
        context,
        titulo: estado.edicao
            ? 'Descartar alterações?'
            : 'Descartar orçamento?',
        mensagem: 'Os dados preenchidos serão perdidos.',
        acao: 'Descartar',
      );
      if (!descartar) return;
    }
    if (mounted) context.pop();
  }

  Future<void> _continuar() async {
    final wizard = ref.read(_provider.notifier);
    final estado = ref.read(_provider).requireValue!;
    switch (estado.etapa) {
      case 1:
        if (_formCliente.currentState!.validate()) wizard.avancar();
      case 2:
        if (!wizard.avancar()) _avisar('Adicione pelo menos 1 item.');
      case 3:
        wizard.avancar();
      default:
        await _concluir(estado.edicao);
    }
  }

  Future<void> _concluir(bool edicao) async {
    setState(() => _salvando = true);
    final String id;
    try {
      id = await ref.read(_provider.notifier).concluir();
    } on Object {
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Não foi possível salvar o orçamento. Tente novamente.');
      return;
    }
    if (!mounted) return;
    // Na edição, os detalhes já estão embaixo na pilha e se atualizam
    // sozinhos; um orçamento novo troca o wizard pelos detalhes (RF-24).
    if (edicao) {
      context.pop();
    } else {
      context.pushReplacement(AppRoutes.detalhesOrcamento(id));
    }
  }

  void _avisar(String mensagem) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));

  @override
  Widget build(BuildContext context) {
    return switch (ref.watch(_provider)) {
      AsyncData(value: final OrcamentoWizardState estado) => _wizard(estado),
      AsyncData() => _Mensagem(
        texto: 'Orçamento não encontrado',
        botao: 'Voltar',
        icone: Icons.arrow_back,
        onPressed: () => context.pop(),
      ),
      AsyncError() => _Mensagem(
        texto: 'Não foi possível carregar o orçamento.',
        botao: 'Tentar novamente',
        icone: Icons.refresh,
        onPressed: () => ref
          ..invalidate(orcamentosProvider)
          ..invalidate(produtosCatalogoProvider)
          ..invalidate(_provider),
      ),
      _ => Scaffold(
        appBar: AppTopBar(onBack: () => context.pop()),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _wizard(OrcamentoWizardState estado) {
    final colors = context.colors;
    final etapa = estado.etapa;
    return PopScope(
      canPop: etapa == 1 && !estado.alterado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_voltar());
      },
      child: Scaffold(
        appBar: AppTopBar(onBack: _voltar),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // Cada etapa começa do topo.
                  key: ValueKey('etapa-$etapa'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        estado.edicao ? 'Editar Orçamento' : 'Novo Orçamento',
                        style: AppTextStyles.display.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Etapa $etapa de $totalEtapasWizard: '
                        '${_subtitulos[etapa - 1]}',
                        style: AppTextStyles.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      StepProgressBar(etapaAtual: etapa),
                      const SizedBox(height: AppSpacing.lg),
                      switch (etapa) {
                        1 => EtapaCliente(
                          provider: _provider,
                          formKey: _formCliente,
                        ),
                        2 => EtapaItens(provider: _provider),
                        3 => EtapaCustos(provider: _provider),
                        _ => EtapaResumo(provider: _provider),
                      },
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    if (etapa > 1)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                        ),
                        onPressed: _voltar,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Voltar'),
                      ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Continuar',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _salvando ? null : _continuar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela de "não encontrado" ou de erro, com uma única ação.
class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.texto,
    required this.botao,
    required this.icone,
    required this.onPressed,
  });

  final String texto;
  final String botao;
  final IconData icone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: Center(
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
              const SizedBox(height: AppSpacing.md),
              OutlinedAppButton(
                label: botao,
                icon: icone,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
