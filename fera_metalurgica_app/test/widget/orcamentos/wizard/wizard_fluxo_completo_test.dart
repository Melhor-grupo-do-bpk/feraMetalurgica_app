import 'dart:async';

import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/fake_local_json_storage.dart';
import 'wizard_teste_helpers.dart';

/// Critério de aceite da T3: o orçamento do Figma (João da Silva, portão
/// basculante, custos de R$ 5.200,00) termina nos detalhes com valor final
/// de R$ 8.450,00 e aparece na lista sem reiniciar o app.
void main() {
  testWidgets(r'fluxo completo grava R$ 8.450,00 para custos de R$ 5.200,00', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = InMemoryJsonStorage();
    await popularDadosIniciais(storage, incluirExemplos: true);
    appRouter.go(AppRoutes.orcamentos);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localJsonStorageProvider.overrideWithValue(storage),
          agoraProvider.overrideWithValue(DateTime(2026, 10, 26, 10)),
        ],
        child: const FeraApp(themeMode: ThemeMode.light),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(appRouter.push(AppRoutes.novoOrcamento()));
    await tester.pumpAndSettle();

    // Etapa 1.
    await preencherCliente(tester);
    await tocar(tester, continuar);

    // Etapa 2.
    await digitar(tester, 'campo-projeto', 'Portão metálico');
    await escolherTipoServico(tester, 'Portão Basculante');
    await digitar(tester, 'campo-medida-A', '2,50');
    await digitar(tester, 'campo-medida-L', '2.20');
    await digitar(tester, 'campo-material', 'Aço Carbono');
    await digitar(
      tester,
      'campo-especificacoes',
      'Estrutura tubular 50×50mm, chapa 18',
    );
    await tocar(tester, find.text('Adicionar Item'));
    await tocar(tester, continuar);

    // Etapa 3.
    await digitarCusto(tester, 'Matéria-prima', '245000');
    await digitarCusto(tester, 'Mão de obra', '180000');
    await digitarCusto(tester, 'Insumos', '35000');
    await digitarCusto(tester, 'Combustível', '18000');
    await digitarCusto(tester, 'Impostos', '42000');
    expect(find.text(r'R$ 5.200,00'), findsOneWidget);
    await tocar(tester, continuar);

    // Etapa 4: só o valor final, nenhum custo interno (D-16).
    expect(find.text('Etapa 4 de 4: Resumo do orçamento'), findsOneWidget);
    expect(find.text(r'R$ 8.450,00'), findsOneWidget);
    expect(find.text(r'R$ 5.200,00'), findsNothing);
    expect(find.text('Portão metálico'), findsOneWidget);
    expect(find.text('15 dias úteis'), findsOneWidget);
    await tocar(tester, continuar);

    // Detalhes do novo orçamento, no lugar do wizard.
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    final detalhes = tester.widget<OrcamentoDetalhesPage>(
      find.byType(OrcamentoDetalhesPage),
    );
    expect(detalhes.orcamentoId, '00483');
    expect(find.text(r'R$ 8.450,00'), findsWidgets);

    final salvo = (await LocalOrcamentoRepository(
      storage,
    ).getAll()).firstWhere((o) => o.id == '00483');
    expect(salvo.status, StatusOrcamento.emAnalise);
    expect(salvo.criadoEm, DateTime(2026, 10, 26, 10));
    expect(salvo.valorFinal, 8450);
    expect(salvo.itens.single.produtoId, 'produto-portao-basculante');

    // Voltar dos detalhes leva à lista, que já mostra o orçamento.
    await tocar(tester, find.byTooltip('Voltar'));
    expect(find.byType(OrcamentosListaPage), findsOneWidget);
    expect(find.text('#00483'), findsOneWidget);
  });
}
