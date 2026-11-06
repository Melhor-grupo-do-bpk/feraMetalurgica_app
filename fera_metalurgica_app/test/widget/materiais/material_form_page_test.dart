import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../mocks/container_de_teste.dart';
import '../../mocks/dados_exemplo.dart';
import '../core/teste_helpers.dart';

void main() {
  final nome = find.byKey(const ValueKey('material-nome'));
  final preco = find.byKey(const ValueKey('material-preco'));
  final salvar = find.text('Salvar material');

  Finder segmento(String simbolo) => find.descendant(
    of: find.byKey(const ValueKey('material-unidade')),
    matching: find.text(simbolo),
  );

  Future<Material> salvo(WidgetTester tester, String id) async =>
      (await containerDoApp(
        tester,
      ).read(materialRepositoryProvider).buscarPorId(id))!;

  /// Banco só com o orçamento C (granito e madeira em uso) e os materiais
  /// de exemplo, mais um "Aço" que nenhuma peça usa (D-40).
  const aco = Material(
    id: 'material-aco',
    nome: 'Aço carbono',
    unidade: UnidadeCobranca.m2,
    precoReferencia: Dinheiro(5000),
  );
  Future<List<Override>> bancoComUso() async {
    final banco = await bancoComOrcamentos([orcamentoExemploC]);
    final repositorio = SqliteMaterialRepository(banco);
    for (final material in [...materiaisExemplo, aco]) {
      await repositorio.salvar(material);
    }
    return [bancoDeDadosProvider.overrideWithValue(banco)];
  }

  group('contrato do atalho "Cadastrar material" (HO-V2-A-02)', () {
    testWidgets('push<String>(material()) devolve o id do material salvo', (
      tester,
    ) async {
      await abrirEm(tester, AppRoutes.materiais);
      final contexto = tester.element(find.byType(MateriaisPage));
      final resultado = GoRouter.of(
        contexto,
      ).push<String>(AppRoutes.material());
      await tester.pumpAndSettle();

      await digitar(tester, nome, 'Aço inox 304');
      await digitar(tester, preco, '120,50');
      await tocar(tester, salvar);

      final id = await resultado;
      expect(id, isNotNull);
      final material = await salvo(tester, id!);
      expect(material.nome, 'Aço inox 304');
      expect(material.unidade, UnidadeCobranca.m2);
      expect(material.precoReferencia, const Dinheiro(12050));
      expect(material.ativo, isTrue);
      expect(find.byType(MateriaisPage), findsOneWidget);
    });

    testWidgets('voltar sem salvar devolve null', (tester) async {
      await abrirEm(tester, AppRoutes.materiais);
      final contexto = tester.element(find.byType(MateriaisPage));
      final resultado = GoRouter.of(
        contexto,
      ).push<String>(AppRoutes.material());
      await tester.pumpAndSettle();

      await digitar(tester, nome, 'Rascunho');
      await tocar(tester, find.byTooltip('Voltar'));

      expect(await resultado, isNull);
    });
  });

  testWidgets('"Novo" na lista cria o material em m³ e o mostra', (
    tester,
  ) async {
    await abrirEm(tester, AppRoutes.materiais);

    await tocar(tester, find.text('Novo'));
    expect(find.text('Novo material'), findsOneWidget);
    await digitar(tester, nome, 'Concreto usinado');
    await tocar(tester, segmento('m³'));
    await digitar(tester, preco, '450,00');
    await tocar(tester, salvar);

    expect(find.text('Material salvo.'), findsOneWidget);
    expect(find.text('Concreto usinado'), findsOneWidget);
    expect(find.text(r'R$ 450,00/m³'), findsOneWidget);
  });

  group('mensagens por campo', () {
    testWidgets('nome e preço vazios', (tester) async {
      await abrirEm(tester, AppRoutes.material());

      await tocar(tester, salvar);

      expect(find.text('Campo obrigatório'), findsNWidgets(2));
      expect(find.byType(MaterialFormPage), findsOneWidget);

      await digitar(tester, nome, 'Granito');
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('preço zero', (tester) async {
      await abrirEm(tester, AppRoutes.material());

      await digitar(tester, nome, 'Granito');
      await digitar(tester, preco, '0');
      await tocar(tester, salvar);

      expect(
        find.text('O preço de referência deve ser maior que zero'),
        findsOneWidget,
      );
    });
  });

  testWidgets('editar o material não muda o orçamento salvo', (tester) async {
    final overrides = await overridesDeTeste();
    await abrirEm(
      tester,
      AppRoutes.material(id: mdfExemplo.id),
      overrides: overrides,
    );
    expect(find.text('Editar material'), findsOneWidget);
    expect(find.text(mdfExemplo.nome), findsOneWidget);

    await digitar(tester, preco, '100,00');
    await tocar(tester, salvar);

    expect(
      (await salvo(tester, mdfExemplo.id)).precoReferencia,
      const Dinheiro(10000),
    );
    final [b, _] = await orcamentosGravados(overrides);
    final pecaMdf = b.itens
        .expand((item) => item.pecas)
        .firstWhere((p) => p.material.materialOrigemId == mdfExemplo.id);
    expect(pecaMdf.material.precoAplicado, const Dinheiro(9000));
    expect(b.totalGeral, orcamentoExemploB.totalGeral);
  });

  group('troca de unidade (D-40)', () {
    testWidgets('material em uso: bloqueia e explica', (tester) async {
      await abrirEm(
        tester,
        AppRoutes.material(id: granitoExemplo.id),
        overrides: await bancoComUso(),
      );
      expect(find.text(mensagemUnidadeEmUso), findsOneWidget);

      await tocar(tester, segmento('m³'));

      expect(find.text('A unidade não pode mudar'), findsOneWidget);
      await tocar(tester, find.text('Entendi'));
      await digitar(tester, preco, '310,00');
      await tocar(tester, salvar);

      final material = await salvo(tester, granitoExemplo.id);
      expect(material.unidade, UnidadeCobranca.m2);
      expect(material.precoReferencia, const Dinheiro(31000));
    });

    testWidgets('material sem uso: troca livre', (tester) async {
      await abrirEm(
        tester,
        AppRoutes.material(id: aco.id),
        overrides: await bancoComUso(),
      );
      expect(find.text(mensagemUnidadeEmUso), findsNothing);

      await tocar(tester, segmento('m³'));

      expect(find.text('A unidade não pode mudar'), findsNothing);
      await tocar(tester, salvar);
      expect((await salvo(tester, aco.id)).unidade, UnidadeCobranca.m3);
    });
  });

  testWidgets('inativar e reativar no formulário, sem perder o digitado', (
    tester,
  ) async {
    await abrirEm(tester, AppRoutes.material(id: mdfExemplo.id));
    await digitar(tester, nome, 'MDF 18 mm');

    await tocar(tester, find.text('Inativar material'));
    await tocar(tester, find.widgetWithText(TextButton, 'Inativar'));

    expect(find.text('Material inativado.'), findsOneWidget);
    expect(find.text('Inativo'), findsOneWidget);
    expect(find.text('MDF 18 mm'), findsOneWidget);
    expect((await salvo(tester, mdfExemplo.id)).ativo, isFalse);

    await tocar(tester, find.text('Reativar material'));
    expect(find.text('Material reativado.'), findsOneWidget);
    expect(find.text('Inativo'), findsNothing);
    expect((await salvo(tester, mdfExemplo.id)).ativo, isTrue);
  });

  testWidgets('salvar um inativo o mantém inativo', (tester) async {
    await abrirEm(tester, AppRoutes.materiais);
    await containerDoApp(
      tester,
    ).read(materiaisProvider.notifier).inativar(mdfExemplo.id);
    appRouter.go(AppRoutes.material(id: mdfExemplo.id));
    await tester.pumpAndSettle();

    await digitar(tester, preco, '95,00');
    await tocar(tester, salvar);

    final material = await salvo(tester, mdfExemplo.id);
    expect(material.ativo, isFalse);
    expect(material.precoReferencia, const Dinheiro(9500));
  });

  testWidgets('id inexistente', (tester) async {
    await abrirEm(tester, AppRoutes.material(id: 'nao-existe'));

    expect(find.text('Material não encontrado.'), findsOneWidget);
  });

  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('360 dp com erros e o aviso de unidade, ${tema.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await abrirEm(
        tester,
        AppRoutes.material(id: granitoExemplo.id),
        overrides: await bancoComUso(),
        themeMode: tema,
        tamanho: const Size(360, 640),
      );
      await digitar(tester, nome, '');
      await tocar(tester, salvar);
      await conferirAcessibilidade(tester);

      await tocar(tester, segmento('m³'));
      await conferirAcessibilidade(tester);
      semantics.dispose();
    });
  }
}
