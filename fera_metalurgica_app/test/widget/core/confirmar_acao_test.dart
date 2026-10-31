import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/widgets/confirmar_acao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  /// Monta um botão que abre o diálogo e guarda a resposta em [respostas].
  Future<void> montar(
    WidgetTester tester,
    List<bool> respostas, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => respostas.add(
            await confirmarAcao(
              context,
              titulo: 'Excluir tarefa?',
              mensagem: 'Esta ação não pode ser desfeita.',
              acao: 'Excluir',
            ),
          ),
          child: const Text('Abrir'),
        ),
      ),
      themeMode: themeMode,
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra título, mensagem, "Cancelar" e a ação', (tester) async {
    await montar(tester, []);

    expect(find.text('Excluir tarefa?'), findsOneWidget);
    expect(find.text('Esta ação não pode ser desfeita.'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('a ação devolve true', (tester) async {
    final respostas = <bool>[];
    await montar(tester, respostas);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(respostas, [true]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('"Cancelar" devolve false', (tester) async {
    final respostas = <bool>[];
    await montar(tester, respostas);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(respostas, [false]);
  });

  testWidgets('tocar fora devolve false', (tester) async {
    final respostas = <bool>[];
    await montar(tester, respostas);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(respostas, [false]);
  });

  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('ação na cor de erro e contraste, ${tema.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await montar(tester, [], themeMode: tema);

      final contexto = tester.element(find.text('Excluir'));
      final cor = DefaultTextStyle.of(contexto).style.color;
      expect(cor, contexto.colors.error);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }
}
