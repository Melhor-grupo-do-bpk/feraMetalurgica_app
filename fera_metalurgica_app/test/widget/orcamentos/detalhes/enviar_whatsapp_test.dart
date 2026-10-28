import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_orcamento_repository.dart';
import '../../../mocks/mock_whatsapp_launcher.dart';
import '../../core/pump_themed.dart';

/// "Enviar WhatsApp" nos detalhes (RF-34, D-06, D-15), com o launcher
/// mockado. Os demais testes dos detalhes são da T2.
void main() {
  late MockOrcamentoRepository repository;
  late MockWhatsappLauncher launcher;

  setUpAll(() => registerFallbackValue(orcamentosSeed.first));

  setUp(() {
    // O repositório guarda o que é salvo, para a tela refletir o status novo.
    var salvos = [...orcamentosSeed];
    repository = MockOrcamentoRepository();
    when(() => repository.getAll()).thenAnswer((_) async => salvos);
    when(() => repository.save(any())).thenAnswer((invocation) async {
      final orcamento = invocation.positionalArguments.single as Orcamento;
      salvos = salvos.map((o) => o.id == orcamento.id ? orcamento : o).toList();
    });
    launcher = MockWhatsappLauncher();
  });

  Future<void> abrirDetalhes(WidgetTester tester, String id) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpThemed(
      tester,
      ProviderScope(
        overrides: [
          orcamentoRepositoryProvider.overrideWithValue(repository),
          whatsappLauncherProvider.overrideWithValue(launcher),
        ],
        child: OrcamentoDetalhesPage(orcamentoId: id),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Status de [id] como a lista e o dashboard o veem (a Tela 6 não tem
  /// chip de status; o chip "Enviado" é o da lista).
  Future<StatusOrcamento?> statusSalvo(WidgetTester tester, String id) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OrcamentoDetalhesPage)),
    );
    return (await container.read(orcamentoPorIdProvider(id).future))?.status;
  }

  void launcherResponde({required bool abriu}) => when(
    () => launcher.abrirWhatsApp(any(), any()),
  ).thenAnswer((_) async => abriu);

  testWidgets('abre a conversa do cliente com o resumo e passa a "Enviado"', (
    tester,
  ) async {
    launcherResponde(abriu: true);
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    final orcamento = orcamentosSeed.firstWhere((o) => o.id == '00482');
    verify(
      () => launcher.abrirWhatsApp(
        '(99) 99999-9999',
        montarMensagemWhatsApp(orcamento),
      ),
    ).called(1);
    final salvo =
        verify(() => repository.save(captureAny())).captured.single
            as Orcamento;
    expect(salvo, orcamento.copyWith(status: StatusOrcamento.enviado));
    expect(await statusSalvo(tester, '00482'), StatusOrcamento.enviado);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('fora de "Em análise", abre mas não muda o status', (
    tester,
  ) async {
    launcherResponde(abriu: true);
    await abrirDetalhes(tester, '00481');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    verify(() => launcher.abrirWhatsApp(any(), any())).called(1);
    verifyNever(() => repository.save(any()));
    expect(await statusSalvo(tester, '00481'), StatusOrcamento.aprovado);
  });

  testWidgets('se não abrir, mostra o SnackBar e mantém o status', (
    tester,
  ) async {
    launcherResponde(abriu: false);
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível abrir o WhatsApp. Confira o número do cliente.',
      ),
      findsOneWidget,
    );
    verifyNever(() => repository.save(any()));
    expect(await statusSalvo(tester, '00482'), StatusOrcamento.emAnalise);
  });
}
