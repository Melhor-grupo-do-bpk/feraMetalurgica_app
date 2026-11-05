import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/mais/mais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/container_de_teste.dart';
import '../core/teste_helpers.dart';

void main() {
  Finder campo(String chave) => find.byKey(ValueKey('empresa-$chave'));
  final salvar = find.text('Salvar dados');

  String textoDe(WidgetTester tester, String chave) =>
      tester.widget<TextField>(campo(chave)).controller!.text;

  Future<void> preencherObrigatorios(WidgetTester tester) async {
    await digitar(tester, campo('nome'), 'Serralheria Exemplo');
    await digitar(tester, campo('documento'), '11444777000161');
    await digitar(tester, campo('telefone'), '51999998888');
    await digitar(tester, campo('logradouro'), 'Rua das Indústrias');
    await digitar(tester, campo('numero'), 's/n');
    await digitar(tester, campo('bairro'), 'Centro');
    await digitar(tester, campo('cidade'), 'Porto Alegre');
    await digitar(tester, campo('uf'), 'rs');
  }

  testWidgets('instalação nova: salvar libera o "Novo orçamento"', (
    tester,
  ) async {
    await abrirEm(
      tester,
      AppRoutes.dashboard,
      overrides: await overridesDeTeste(semEmpresa: true),
    );

    await tocar(tester, find.text('Criar orçamento'));
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    expect(find.byType(EmpresaPage), findsOneWidget);
    expect(find.textContaining('para liberar o "Novo'), findsOneWidget);

    await preencherObrigatorios(tester);
    await tocar(tester, salvar);

    expect(find.text('Dados da empresa salvos.'), findsOneWidget);
    expect(find.byType(EmpresaPage), findsNothing);
    expect(find.byType(DashboardPage), findsOneWidget);
    final empresa = containerDoApp(tester).read(dadosEmpresaProvider).value!;
    expect(empresa.nomeRazaoSocial, 'Serralheria Exemplo');
    expect(empresa.documento.valorNormalizado, '11444777000161');
    expect(empresa.endereco.uf, 'RS');
    expect(empresa.endereco.numero, 's/n');
    expect(empresa.email, isNull);
    expect(empresa.endereco.cep, isNull);
    expect(empresa.estaCompleta, isTrue);

    await tocar(tester, find.text('Criar orçamento'));
    expect(find.byType(OrcamentoWizardPage), findsOneWidget);
  });

  testWidgets('empresa incompleta bloqueia o novo orçamento', (tester) async {
    await abrirEm(
      tester,
      AppRoutes.dashboard,
      overrides: await overridesDeTeste(semEmpresa: true),
    );
    await tocar(tester, find.text('Criar orçamento'));
    await digitar(tester, campo('nome'), 'Só o nome');
    await tocar(tester, salvar);

    expect(find.byType(EmpresaPage), findsOneWidget);
    expect(containerDoApp(tester).read(dadosEmpresaProvider).value, isNull);

    await tocar(tester, find.byTooltip('Voltar'));
    await tocar(tester, find.text('Criar orçamento'));
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    expect(find.byType(EmpresaPage), findsOneWidget);
  });

  testWidgets('máscaras de CPF/CNPJ, telefone, CEP e UF', (tester) async {
    await abrirEm(
      tester,
      AppRoutes.empresa,
      overrides: await overridesDeTeste(semEmpresa: true),
    );

    await digitar(tester, campo('documento'), '52998224725');
    expect(textoDe(tester, 'documento'), '529.982.247-25');
    await digitar(tester, campo('documento'), '11444777000161');
    expect(textoDe(tester, 'documento'), '11.444.777/0001-61');
    await digitar(tester, campo('telefone'), '5133334444');
    expect(textoDe(tester, 'telefone'), '(51) 3333-4444');
    await digitar(tester, campo('telefone'), '51999998888');
    expect(textoDe(tester, 'telefone'), '(51) 99999-8888');
    await digitar(tester, campo('cep'), '90.010-000x123');
    expect(textoDe(tester, 'cep'), '90010000');
    await digitar(tester, campo('uf'), 's1p');
    expect(textoDe(tester, 'uf'), 'SP');
  });

  group('mensagens por campo', () {
    testWidgets('obrigatórios vazios', (tester) async {
      // Tela alta: a lista monta todos os campos e a contagem vê todos.
      await abrirEm(
        tester,
        AppRoutes.empresa,
        overrides: await overridesDeTeste(semEmpresa: true),
        tamanho: const Size(412, 2400),
      );

      await tocar(tester, salvar);

      // Nome, documento, telefone, logradouro, número, bairro, cidade, UF.
      expect(find.text('Campo obrigatório'), findsNWidgets(8));
      await digitar(tester, campo('nome'), 'Serralheria');
      expect(find.text('Campo obrigatório'), findsNWidgets(7));
    });

    testWidgets('documento, telefone, e-mail e CEP inválidos', (tester) async {
      await abrirEm(
        tester,
        AppRoutes.empresa,
        overrides: await overridesDeTeste(semEmpresa: true),
        tamanho: const Size(412, 2400),
      );
      await preencherObrigatorios(tester);
      await digitar(tester, campo('documento'), '11111111111');
      await digitar(tester, campo('telefone'), '519999');
      await digitar(tester, campo('email'), 'contato@');
      await digitar(tester, campo('cep'), '9001');

      await tocar(tester, salvar);

      expect(find.text('CPF inválido'), findsOneWidget);
      expect(find.text('Telefone inválido'), findsOneWidget);
      expect(find.text('E-mail inválido'), findsOneWidget);
      expect(find.text('CEP inválido: informe 8 dígitos'), findsOneWidget);
      expect(containerDoApp(tester).read(dadosEmpresaProvider).value, isNull);
    });

    testWidgets('rola até o primeiro erro', (tester) async {
      await abrirEm(
        tester,
        AppRoutes.empresa,
        overrides: await overridesDeTeste(semEmpresa: true),
        tamanho: const Size(360, 640),
      );
      await preencherObrigatorios(tester);
      await digitar(tester, campo('nome'), '');
      await tocar(tester, salvar);

      final topo = tester.getTopLeft(campo('nome')).dy;
      expect(topo, inInclusiveRange(0, 640));
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });
  });

  testWidgets('editar mostra os dados atuais e volta para "Mais"', (
    tester,
  ) async {
    await abrirEm(tester, AppRoutes.empresa);
    expect(textoDe(tester, 'nome'), empresaExemplo.nomeRazaoSocial);
    expect(textoDe(tester, 'documento'), '11.444.777/0001-61');
    expect(textoDe(tester, 'telefone'), '(11) 3333-4444');
    expect(find.textContaining('não mudam'), findsOneWidget);

    await digitar(tester, campo('nome'), 'Fera Metalúrgica S.A.');
    await tocar(tester, salvar);

    expect(find.byType(MaisPage), findsOneWidget);
    expect(find.text('Dados da empresa salvos.'), findsOneWidget);
    final empresa = containerDoApp(tester).read(dadosEmpresaProvider).value!;
    expect(empresa.id, empresaExemplo.id);
    expect(empresa.nomeRazaoSocial, 'Fera Metalúrgica S.A.');
  });

  testWidgets('editar a empresa não muda o orçamento salvo', (tester) async {
    final overrides = await overridesDeTeste();
    await abrirEm(tester, AppRoutes.empresa, overrides: overrides);

    await digitar(tester, campo('nome'), 'Outro Nome Ltda');
    await tocar(tester, salvar);

    final [b, c] = await orcamentosGravados(overrides);
    expect(b.emitente.nomeRazaoSocial, empresaExemplo.nomeRazaoSocial);
    expect(c.emitente.nomeRazaoSocial, empresaExemplo.nomeRazaoSocial);
  });

  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('360 dp com erros, ${tema.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await abrirEm(
        tester,
        AppRoutes.empresa,
        overrides: await overridesDeTeste(semEmpresa: true),
        themeMode: tema,
        tamanho: const Size(360, 640),
      );
      await digitar(tester, campo('uf'), 'r');
      await tocar(tester, salvar);
      await conferirAcessibilidade(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await conferirAcessibilidade(tester);
      semantics.dispose();
    });
  }
}
