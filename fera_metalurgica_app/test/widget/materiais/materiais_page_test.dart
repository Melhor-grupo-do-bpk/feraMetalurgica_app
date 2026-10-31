import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/banco_de_teste.dart';
import 'materiais_teste_helpers.dart';

void main() {
  Finder cartao(Material material) =>
      find.byKey(ValueKey('material-${material.id}'));

  Future<void> escolherNoMenu(
    WidgetTester tester,
    Material material,
    String acao,
  ) async {
    await tocar(tester, find.byTooltip('Ações do material ${material.nome}'));
    await tocar(tester, find.text(acao).last);
  }

  testWidgets('lista os materiais com preço por unidade', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);

    expect(find.text('Materiais'), findsWidgets);
    expect(find.text(granitoExemplo.nome), findsOneWidget);
    expect(find.text(r'R$ 300,00/m²'), findsOneWidget);
    expect(find.text(madeiraExemplo.nome), findsOneWidget);
    expect(find.text(r'R$ 3.500,00/m³'), findsOneWidget);
    expect(find.text(mdfExemplo.nome), findsOneWidget);
    expect(find.text('Inativo'), findsNothing);
  });

  testWidgets('a busca ignora maiúsculas e acentos', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);

    await digitar(
      tester,
      find.byKey(const ValueKey('materiais-busca')),
      'ESPÉCIE',
    );

    expect(cartao(madeiraExemplo), findsOneWidget);
    expect(cartao(granitoExemplo), findsNothing);
    expect(cartao(mdfExemplo), findsNothing);

    await digitar(tester, find.byKey(const ValueKey('materiais-busca')), 'xyz');
    expect(find.text('Nenhum material encontrado'), findsOneWidget);
  });

  testWidgets('inativar some de Ativos e das novas seleções', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);

    await escolherNoMenu(tester, mdfExemplo, 'Inativar');
    expect(find.text('Inativar material?'), findsOneWidget);
    await tocar(tester, find.widgetWithText(TextButton, 'Inativar'));

    expect(find.text('Material inativado.'), findsOneWidget);
    expect(cartao(mdfExemplo), findsNothing);
    final ativos = containerDoApp(
      tester,
    ).read(materiaisAtivosProvider).requireValue;
    expect(ativos.map((m) => m.id), isNot(contains(mdfExemplo.id)));

    await tocar(tester, find.text('Todos'));
    expect(cartao(mdfExemplo), findsOneWidget);
    expect(
      find.descendant(of: cartao(mdfExemplo), matching: find.text('Inativo')),
      findsOneWidget,
    );
  });

  testWidgets('cancelar a inativação mantém o material ativo', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);

    await escolherNoMenu(tester, mdfExemplo, 'Inativar');
    await tocar(tester, find.text('Cancelar'));

    expect(cartao(mdfExemplo), findsOneWidget);
    final todos = containerDoApp(tester).read(materiaisProvider).requireValue;
    expect(todos.firstWhere((m) => m.id == mdfExemplo.id).ativo, isTrue);
  });

  testWidgets('reativar devolve o material às novas seleções', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);
    await containerDoApp(
      tester,
    ).read(materiaisProvider.notifier).inativar(granitoExemplo.id);
    await tester.pumpAndSettle();

    await tocar(tester, find.text('Todos'));
    await escolherNoMenu(tester, granitoExemplo, 'Reativar');

    expect(find.text('Material reativado.'), findsOneWidget);
    final ativos = containerDoApp(
      tester,
    ).read(materiaisAtivosProvider).requireValue;
    expect(ativos.map((m) => m.id), contains(granitoExemplo.id));
  });

  testWidgets('tocar no cartão abre a edição', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);

    await tocar(tester, find.text(granitoExemplo.nome));

    expect(find.byType(MaterialFormPage), findsOneWidget);
    expect(find.text('Editar material'), findsOneWidget);
  });

  testWidgets('sem cadastro, mostra o vazio com "Novo"', (tester) async {
    final banco = await bancoDeTeste();
    addTearDown(banco.close);
    await abrirEm(
      tester,
      AppRoutes.materiais,
      overrides: [bancoDeDadosProvider.overrideWithValue(banco)],
    );

    expect(find.text('Nenhum material cadastrado'), findsOneWidget);
    expect(find.text('Novo'), findsNWidgets(2));
  });

  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('360 dp com um inativo e o diálogo, ${tema.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await abrirEm(
        tester,
        AppRoutes.materiais,
        themeMode: tema,
        tamanho: const Size(360, 640),
      );
      await containerDoApp(
        tester,
      ).read(materiaisProvider.notifier).inativar(madeiraExemplo.id);
      await tocar(tester, find.text('Todos'));
      await conferirAcessibilidade(tester);

      await escolherNoMenu(tester, granitoExemplo, 'Inativar');
      await conferirAcessibilidade(tester);
      semantics.dispose();
    });
  }
}
