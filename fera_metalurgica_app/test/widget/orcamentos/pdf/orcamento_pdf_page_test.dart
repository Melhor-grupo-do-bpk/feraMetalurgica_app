import 'dart:convert';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/pdf/previa_pdf_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/printing.dart';

import '../../../mocks/mock_orcamento_repository.dart';

/// Prévia do PDF (Tela 7, RF-40 a RF-42). Os testes não têm a parte nativa
/// do `printing`: a disponibilidade da prévia é sobrescrita e o canal
/// `net.nfet.printing` é simulado para o "Baixar".
void main() {
  const canalPrinting = MethodChannel('net.nfet.printing');
  late MockOrcamentoRepository repository;

  setUp(() {
    repository = MockOrcamentoRepository();
    when(() => repository.getAll()).thenAnswer((_) async => orcamentosSeed);
  });

  /// Abre a prévia de [id] por cima de uma tela de detalhes de mentira.
  Future<void> abrirPrevia(
    WidgetTester tester,
    String id, {
    bool previaDisponivel = false,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.detalhesOrcamento(id),
      routes: [
        GoRoute(
          path: '${AppRoutes.orcamentos}/:id',
          builder: (_, state) => Text('detalhes ${state.pathParameters['id']}'),
          routes: [
            GoRoute(
              path: 'pdf',
              builder: (_, state) =>
                  OrcamentoPdfPage(orcamentoId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orcamentoRepositoryProvider.overrideWithValue(repository),
          previaPdfDisponivelProvider.overrideWith(
            (ref) async => previaDisponivel,
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go(AppRoutes.pdfOrcamento(id));
    if (previaDisponivel) {
      // O `PdfPreview` real fica rasterizando (sem parte nativa), então
      // não dá para esperar a tela "assentar".
      for (
        var i = 0;
        i < 10 && find.byType(PdfPreview).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// Simula o `Printing.sharePdf` e devolve as chamadas recebidas.
  List<MethodCall> simularCompartilhamento(
    WidgetTester tester, {
    bool falhar = false,
  }) {
    final chamadas = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      canalPrinting,
      (call) async {
        chamadas.add(call);
        if (falhar) throw PlatformException(code: 'erro');
        return 1;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        canalPrinting,
        null,
      ),
    );
    return chamadas;
  }

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'mostra a prévia do #00482 com Voltar e Baixar (${modo.name})',
      (tester) async {
        await abrirPrevia(
          tester,
          '00482',
          previaDisponivel: true,
          themeMode: modo,
        );

        final previa = tester.widget<PdfPreview>(find.byType(PdfPreview));
        expect(previa.useActions, isFalse);
        expect(previa.allowSharing, isFalse);
        expect(previa.allowPrinting, isFalse);
        expect(previa.canChangePageFormat, isFalse);
        expect(previa.pdfFileName, 'orcamento-00482.pdf');
        expect(find.text('Voltar'), findsOneWidget);
        expect(find.text('Baixar'), findsOneWidget);
      },
    );
  }

  testWidgets('sem prévia na plataforma, avisa e mantém o Baixar', (
    tester,
  ) async {
    await abrirPrevia(tester, '00482');

    expect(find.byType(PdfPreview), findsNothing);
    expect(find.textContaining('prévia não está disponível'), findsOneWidget);
    expect(find.text('Baixar'), findsOneWidget);
  });

  testWidgets('"Baixar" compartilha orcamento-00482.pdf (RF-42)', (
    tester,
  ) async {
    final chamadas = simularCompartilhamento(tester);
    await abrirPrevia(tester, '00482');

    await tester.tap(find.text('Baixar'));
    await tester.pumpAndSettle();

    final compartilhar = chamadas.singleWhere((c) => c.method == 'sharePdf');
    final argumentos = compartilhar.arguments as Map<Object?, Object?>;
    expect(argumentos['name'], 'orcamento-00482.pdf');
    final bytes = argumentos['doc']! as Uint8List;
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('se o compartilhamento falhar, mostra o SnackBar', (
    tester,
  ) async {
    simularCompartilhamento(tester, falhar: true);
    await abrirPrevia(tester, '00482');

    await tester.tap(find.text('Baixar'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível compartilhar o PDF.'), findsOneWidget);
  });

  testWidgets('"Voltar" do rodapé volta aos detalhes', (tester) async {
    await abrirPrevia(tester, '00482');

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('detalhes 00482'), findsOneWidget);
  });

  testWidgets('id inexistente mostra "não encontrado"', (tester) async {
    await abrirPrevia(tester, '99999');

    expect(find.text('Orçamento não encontrado'), findsOneWidget);
    expect(find.text('Baixar'), findsNothing);
  });

  testWidgets('erro ao carregar oferece "Tentar novamente"', (tester) async {
    when(() => repository.getAll()).thenThrow(Exception('falhou'));
    await abrirPrevia(tester, '00482');

    expect(find.text('Não foi possível carregar o orçamento.'), findsOneWidget);

    when(() => repository.getAll()).thenAnswer((_) async => orcamentosSeed);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Baixar'), findsOneWidget);
  });
}
