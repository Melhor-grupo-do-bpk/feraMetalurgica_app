import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/aviso_total_zero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/container_de_teste.dart';
import 'wizard_teste_helpers.dart';

/// Etapa 3 (prompt §4 e §6) pela edição do exemplo C (A + B, insumos
/// 100,00, impostos 200,00, combustível 50,00, outros 30,00 "Frete",
/// desconto 100,00, validade de 15 dias: R$ 3.630,80). "Agora" é
/// 26/10/2026, 10h.
void main() {
  final agora = DateTime(2026, 10, 26, 10);
  late List<Override> overrides;
  late Orcamento c;

  setUp(() async {
    overrides = await overridesDeTeste(agora: agora);
    c = (await orcamentosGravados(overrides)).last;
  });

  Finder campo(String nome) => find.descendant(
    of: find.byKey(ValueKey('valores-$nome')),
    matching: find.byType(EditableText),
  );

  Finder totalGeral(String valor) => find.descendant(
    of: find.byKey(const ValueKey('valores-total-geral')),
    matching: find.text(valor),
  );

  Future<void> digitar(WidgetTester tester, String nome, String texto) async {
    await tester.ensureVisible(campo(nome));
    await tester.enterText(campo(nome), texto);
    await tester.pumpAndSettle();
  }

  /// Abre a edição do exemplo C com `abrirWizard` e vai até a etapa 3.
  Future<void> abrirEtapa3(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    Size tamanho = const Size(800, 2400),
  }) async {
    await abrirWizard(
      tester,
      AppRoutes.editarOrcamento(c.id),
      overrides: overrides,
      themeMode: themeMode,
      tamanho: tamanho,
    );
    await tocar(tester, continuar);
    await tocar(tester, continuar);
    expect(find.text('Etapa 3 de 4: Valores'), findsOneWidget);
  }

  testWidgets('mostra os valores salvos, o total e a data-limite', (
    tester,
  ) async {
    await abrirEtapa3(tester);

    expect(find.text('100,00'), findsNWidgets(2)); // insumos e desconto
    expect(find.text('200,00'), findsOneWidget);
    expect(find.text('Frete'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    // A validade conta de "agora", a data da nova revisão.
    expect(find.text('Válido até 10/11/2026'), findsOneWidget);
    expect(totalGeral(r'R$ 3.630,80'), findsOneWidget);
    expect(find.byType(AvisoTotalZero), findsNothing);
  });

  testWidgets(r'cenário C digitado chega a R$ 3.630,80 e é salvo', (
    tester,
  ) async {
    await abrirEtapa3(tester);
    for (final nome in [
      'insumos',
      'impostos',
      'combustivel',
      'outros',
      'desconto',
    ]) {
      await digitar(tester, nome, '');
    }
    await digitar(tester, 'outros-descricao', '');
    // Só os produtos A + B.
    expect(totalGeral(r'R$ 3.350,80'), findsOneWidget);

    await digitar(tester, 'insumos', '100');
    await digitar(tester, 'impostos', '200,00');
    await digitar(tester, 'combustivel', '50');
    await digitar(tester, 'outros', '30');
    await digitar(tester, 'outros-descricao', 'Instalação');
    await digitar(tester, 'desconto', '100,00');
    expect(totalGeral(r'R$ 3.630,80'), findsOneWidget);

    await tocar(tester, continuar);
    expect(find.text('Outros: Instalação'), findsOneWidget);
    await tocar(tester, find.text('Salvar alterações'));

    final salvo = (await orcamentosGravados(overrides)).first;
    expect(salvo.totalGeral.centavos, 363080);
    expect(salvo.outrosDescricao, 'Instalação');
  });

  testWidgets('"outros" maior que zero exige descrição', (tester) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'outros-descricao', '');

    await tocar(tester, continuar);

    expect(find.text('Etapa 3 de 4: Valores'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('valores-outros-descricao')),
        matching: find.text('Campo obrigatório'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('desconto maior que o subtotal não avança', (tester) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'desconto', '3.730,81');

    expect(find.text('Corrija os valores para ver o total geral.'), findsOne);
    await tocar(tester, continuar);

    expect(find.text('Etapa 3 de 4: Valores'), findsOneWidget);
    expect(
      find.text('O desconto não pode ser maior que o subtotal'),
      findsWidgets,
    );
  });

  testWidgets('validade zero não avança', (tester) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'validade', '0');

    expect(find.textContaining('Válido até'), findsNothing);
    await tocar(tester, continuar);

    expect(find.text('Etapa 3 de 4: Valores'), findsOneWidget);
    expect(find.text('A validade deve ser de pelo menos 1 dia'), findsWidgets);
  });

  testWidgets('validade vazia é aceita (sem validade)', (tester) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'validade', '');

    await tocar(tester, continuar);

    expect(find.text('Etapa 4 de 4: Prévia'), findsOneWidget);
    expect(find.textContaining('Válido até'), findsNothing);
  });

  testWidgets('texto inválido mostra o erro e não avança nem volta', (
    tester,
  ) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'insumos', '12,345');

    expect(find.textContaining('Valor inválido'), findsOneWidget);
    // O controller ficou com o último valor válido.
    expect(totalGeral(r'R$ 3.630,80'), findsOneWidget);

    await tocar(tester, continuar);
    expect(find.text('Etapa 3 de 4: Valores'), findsOneWidget);
    expect(find.text('Corrija os campos destacados.'), findsOneWidget);

    await tocar(tester, find.text('Voltar'));
    expect(find.text('Etapa 3 de 4: Valores'), findsOneWidget);
  });

  testWidgets('total geral zero aparece destacado', (tester) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'desconto', '3.730,80');

    expect(totalGeral(r'R$ 0,00'), findsOneWidget);
    expect(find.byType(AvisoTotalZero), findsOneWidget);
  });

  testWidgets('voltar à etapa 2 e avançar de novo mantém os valores', (
    tester,
  ) async {
    await abrirEtapa3(tester);
    await digitar(tester, 'combustivel', '75');
    await digitar(tester, 'observacoes', 'Entrega em 20 dias.');

    await tocar(tester, find.text('Voltar'));
    expect(find.text('Etapa 2 de 4: Produtos'), findsOneWidget);
    await tocar(tester, continuar);

    expect(find.text('75,00'), findsOneWidget);
    expect(find.text('Entrega em 20 dias.'), findsOneWidget);
    expect(totalGeral(r'R$ 3.655,80'), findsOneWidget);
  });

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('360 dp sem transbordar (${modo.name})', (tester) async {
      final semantics = tester.ensureSemantics();
      await abrirEtapa3(tester, themeMode: modo, tamanho: const Size(360, 640));
      await digitar(tester, 'desconto', '3.730,80');

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }
}
