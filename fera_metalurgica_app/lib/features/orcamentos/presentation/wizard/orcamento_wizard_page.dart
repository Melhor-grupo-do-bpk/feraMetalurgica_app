import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/confirmar_acao.dart';
import 'package:fera_metalurgica_app/core/widgets/step_progress_bar.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_cliente.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_previa.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_produtos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_valores.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller_state.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/sair_etapa_produtos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const List<String> _subtitulos = ['Cliente', 'Produtos', 'Valores', 'Prévia'];

/// Wizard de criação/edição de orçamento (prompt §4, D-28, D-30): as 4
/// etapas sobre o `OrcamentoController`, com a navegação entre elas, o
/// descarte com confirmação e o "Finalizar" ("Salvar alterações" na
/// edição).
///
/// Ao salvar, o botão fica bloqueado e mostra o progresso (o controller
/// também ignora a chamada repetida); se a gravação falhar, a sessão
/// continua e dá para tentar de novo. Um orçamento novo abre nos detalhes;
/// a edição volta para os detalhes, que já estão embaixo na pilha.
class OrcamentoWizardPage extends ConsumerStatefulWidget {
  /// Cria o wizard. Com [orcamentoId], edita o orçamento salvo (D-30).
  const OrcamentoWizardPage({this.orcamentoId, super.key});

  /// Orçamento em edição, ou `null` para um orçamento novo.
  final String? orcamentoId;

  @override
  ConsumerState<OrcamentoWizardPage> createState() =>
      _OrcamentoWizardPageState();
}

class _OrcamentoWizardPageState extends ConsumerState<OrcamentoWizardPage> {
  late final Future<void> _inicio;

  OrcamentoController get _controller =>
      ref.read(orcamentoControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // O controller é autoDispose: a página o mantém vivo enquanto existir.
    ref.listenManual(orcamentoControllerProvider, (_, _) {});
    final id = widget.orcamentoId;
    _inicio = id == null
        ? _controller.iniciar()
        : _controller.iniciarEdicao(id);
  }

  /// Formulários das etapas 1 e 3, por etapa: validam o texto digitado que
  /// ainda não é um valor válido (e por isso não chegou ao controller).
  final Map<int, GlobalKey<FormState>> _formularios = {
    1: GlobalKey<FormState>(),
    3: GlobalKey<FormState>(),
  };

  /// Ponto único de saída de uma etapa, para frente ou para trás
  /// ("Continuar", "Voltar", a seta da barra do topo e o voltar do
  /// sistema). Devolve se pode sair; se não puder, já avisou.
  ///
  /// Nas etapas 1 e 3, barra texto inválido nos campos (sair perderia o
  /// que foi digitado). A etapa 2 é da V2-A: o orquestrador liga o
  /// `podeSairDaEtapaProdutos` aqui ao integrar A e B.
  Future<bool> _podeSairDaEtapa(int etapa) async {
    switch (etapa) {
      case 1 || 3:
        final valido = _formularios[etapa]!.currentState?.validate() ?? true;
        if (!valido) _avisar('Corrija os campos destacados.');
        return valido;
      case 2:
        return await podeSairDaEtapaProdutos(context, ref);
      default:
        return true;
    }
  }

  /// Voltar da top bar, do botão e do sistema: volta uma etapa; na etapa 1,
  /// sai do wizard depois de confirmar o descarte (prompt §4).
  Future<void> _voltar() async {
    final estado = ref.read(orcamentoControllerProvider);
    if (estado.finalizando) return;
    if (estado.etapaAtual > 1) {
      if (!await _podeSairDaEtapa(estado.etapaAtual) || !mounted) return;
      _controller.voltar();
      return;
    }
    final descartar = await confirmarAcao(
      context,
      titulo: estado.ehEdicao
          ? 'Descartar alterações?'
          : 'Descartar orçamento?',
      mensagem: estado.ehEdicao
          ? 'As alterações feitas aqui serão perdidas. O orçamento salvo '
                'não muda.'
          : 'Os dados preenchidos serão perdidos.',
      acao: 'Descartar',
    );
    if (!descartar || !mounted) return;
    _controller.descartar();
    context.pop();
  }

  Future<void> _continuar() async {
    final estado = ref.read(orcamentoControllerProvider);
    if (estado.finalizando) return;
    if (estado.etapaAtual < EstadoEdicaoOrcamento.totalEtapas) {
      if (!await _podeSairDaEtapa(estado.etapaAtual) || !mounted) return;
      if (!_controller.avancar()) _avisarErros();
      return;
    }
    final edicao = estado.ehEdicao;
    try {
      final salvo = await _controller.finalizar();
      if (!mounted) return;
      if (salvo == null) {
        _avisarErros();
      } else if (edicao) {
        // Os detalhes já estão embaixo na pilha e se atualizam sozinhos.
        context.pop();
      } else {
        context.pushReplacement(AppRoutes.detalhesOrcamento(salvo.id));
      }
    } on Object {
      if (mounted) {
        _avisar('Não foi possível salvar o orçamento. Tente novamente.');
      }
    }
  }

  void _avisarErros() {
    final erros = ref.read(orcamentoControllerProvider).erros;
    if (erros.isNotEmpty) _avisar(erros.first.mensagem);
  }

  void _avisar(String mensagem) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _inicio,
      builder: (context, inicio) {
        final estado = ref.watch(orcamentoControllerProvider);
        if (inicio.hasError) {
          return _Mensagem(
            texto: 'Não foi possível abrir o orçamento.',
            onVoltar: () => context.pop(),
          );
        }
        if (inicio.connectionState != ConnectionState.done ||
            estado.edicao == null) {
          return Scaffold(
            appBar: AppTopBar(onBack: () => context.pop()),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _wizard(estado);
      },
    );
  }

  Widget _wizard(EstadoEdicaoOrcamento estado) {
    final colors = context.colors;
    final etapa = estado.etapaAtual;
    final ultima = etapa == EstadoEdicaoOrcamento.totalEtapas;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_voltar());
      },
      child: Scaffold(
        appBar: AppTopBar(onBack: _voltar),
        body: SingleChildScrollView(
          // Cada etapa começa do topo.
          key: ValueKey('etapa-$etapa'),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                estado.ehEdicao ? 'Editar Orçamento' : 'Novo Orçamento',
                style: AppTextStyles.display.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Etapa $etapa de ${EstadoEdicaoOrcamento.totalEtapas}: '
                '${_subtitulos[etapa - 1]}',
                style: AppTextStyles.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              StepProgressBar(etapaAtual: etapa),
              const SizedBox(height: AppSpacing.lg),
              switch (etapa) {
                1 => Form(key: _formularios[1], child: const EtapaCliente()),
                2 => const EtapaProdutos(),
                3 => Form(key: _formularios[3], child: const EtapaValores()),
                _ => const EtapaPrevia(),
              },
            ],
          ),
        ),
        // Fora do corpo: o SnackBar aparece acima do rodapé, sem cobrir
        // os botões.
        bottomNavigationBar: SafeArea(
          child: Padding(
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
                    onPressed: estado.finalizando ? null : _voltar,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Voltar'),
                  ),
                // O espaço que sobra é do botão principal, que corta o
                // texto com reticências se não couber.
                if (estado.finalizando)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.xs),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    // Só a altura do botão: no `bottomNavigationBar`, o
                    // Align ocuparia a tela toda.
                    heightFactor: 1,
                    child: PrimaryButton(
                      label: switch ((ultima, estado.finalizando)) {
                        (_, true) => 'Salvando...',
                        (true, _) when estado.ehEdicao => 'Salvar alterações',
                        (true, _) => 'Finalizar',
                        _ => 'Continuar',
                      },
                      trailingIcon: ultima ? Icons.check : Icons.arrow_forward,
                      onPressed: estado.finalizando ? null : _continuar,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela de erro ao abrir o wizard, com o botão de voltar.
class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, required this.onVoltar});

  final String texto;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppTopBar(onBack: onVoltar),
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
                label: 'Voltar',
                icon: Icons.arrow_back,
                onPressed: onVoltar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
