import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/whatsapp/whatsapp_launcher.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/banco_de_teste.dart';
import '../mocks/dados_exemplo.dart';
import '../mocks/mock_whatsapp_launcher.dart';
import 'core/teste_helpers.dart';

/// Fluxo de ponta a ponta da rodada v2 (V2-G), no app completo e num banco
/// vazio, como numa instalação nova de release: cadastra a empresa e os
/// materiais, monta os exemplos A e B do prompt §9 (fechamento C),
/// finaliza, edita (rev. 2), envia pelo WhatsApp e agenda a produção.
///
/// O "agora" é fixo em 28/10/2026 09:00: o primeiro orçamento do dia é o
/// `281026-01`, e a tarefa agendada, "Produção 281026-01".
void main() {
  final agora = DateTime(2026, 10, 28, 9);
  const codigo = '281026-01';

  late MockWhatsappLauncher launcher;

  setUpAll(() => registerFallbackValue(orcamentoExemploC));

  setUp(() {
    launcher = MockWhatsappLauncher();
    when(() => launcher.enviarOrcamento(any())).thenAnswer((_) async => true);
  });

  Future<void> abrirAppVazio(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final banco = await bancoDeTeste();
    addTearDown(banco.close);
    appRouter.go(AppRoutes.dashboard);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bancoDeDadosProvider.overrideWithValue(banco),
          agoraProvider.overrideWithValue(agora),
          whatsappLauncherProvider.overrideWithValue(launcher),
        ],
        child: const FeraApp(themeMode: ThemeMode.light),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chave(String valor) => find.byKey(ValueKey(valor));

  /// Valor [valor] na linha de rótulo [rotulo] (a primeira `Row` em volta
  /// do rótulo), para não confundir com o mesmo valor em outra linha.
  Finder naLinha(String rotulo, String valor) => find.descendant(
    of: find.ancestor(of: find.text(rotulo), matching: find.byType(Row)).first,
    matching: find.text(valor),
  );

  Future<void> cadastrarEmpresa(WidgetTester tester) async {
    // Sem empresa, o "Criar orçamento" leva aos dados da empresa (D-38).
    await tocar(tester, find.text('Criar orçamento'));
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    for (final (campo, texto) in [
      ('nome', 'Serralheria Exemplo Ltda'),
      ('documento', '11444777000161'),
      ('telefone', '51999998888'),
      ('logradouro', 'Rua das Indústrias'),
      ('numero', '100'),
      ('bairro', 'Centro'),
      ('cidade', 'Porto Alegre'),
      ('uf', 'rs'),
    ]) {
      await digitar(tester, chave('empresa-$campo'), texto);
    }
    await tocar(tester, find.text('Salvar dados'));
    expect(find.text('Dados da empresa salvos.'), findsOneWidget);
  }

  Future<void> cadastrarMateriais(WidgetTester tester) async {
    await tocar(tester, find.text('Mais'));
    await tocar(tester, find.text('Materiais'));
    for (final (nome, unidade, preco) in [
      ('Granito', 'm²', '300,00'),
      ('Madeira', 'm³', '3.500,00'),
      ('MDF', 'm²', '90,00'),
    ]) {
      // Com a lista vazia, o estado vazio repete o "Novo" do topo.
      await tocar(tester, find.text('Novo').first);
      await digitar(tester, chave('material-nome'), nome);
      await tocar(
        tester,
        find.descendant(
          of: chave('material-unidade'),
          matching: find.text(unidade),
        ),
      );
      await digitar(tester, chave('material-preco'), preco);
      await tocar(tester, find.text('Salvar material'));
      expect(find.text(nome), findsOneWidget);
    }
  }

  Future<void> preencherCliente(WidgetTester tester) async {
    for (final (campo, texto) in [
      ('nome', 'Maria Souza'),
      ('documento', '52998224725'),
      ('celular', '51988887777'),
      ('logradouro', 'Rua das Flores'),
      ('numero', '25'),
      ('bairro', 'Moinhos'),
      ('cidade', 'Porto Alegre'),
      ('uf', 'rs'),
    ]) {
      await digitar(tester, chave('cliente-$campo'), texto);
    }
  }

  Future<void> escrever(WidgetTester tester, String campo, String texto) =>
      digitar(tester, chave(campo), texto);

  Future<void> peca(
    WidgetTester tester, {
    required String descricao,
    required String material,
    required String comprimento,
    required String largura,
    String? espessura,
    String quantidade = '1',
  }) async {
    await escrever(tester, 'peca-descricao', descricao);
    await tocar(tester, chave('peca-material'));
    await tocar(
      tester,
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(material),
      ),
    );
    await escrever(tester, 'peca-comprimento', comprimento);
    await escrever(tester, 'peca-largura', largura);
    if (espessura != null) await escrever(tester, 'peca-espessura', espessura);
    await escrever(tester, 'peca-quantidade', quantidade);
    await tocar(tester, find.text('Adicionar peça'));
  }

  Future<void> produto(
    WidgetTester tester, {
    required String descricao,
    required String quantidade,
    required String precoBase,
  }) async {
    await tocar(
      tester,
      find.textContaining(RegExp('^(Adicionar|Novo) produto')).first,
    );
    await escrever(tester, 'produto-descricao', descricao);
    await escrever(tester, 'produto-quantidade', quantidade);
    await escrever(tester, 'produto-preco-base', precoBase);
  }

  Future<void> valor(WidgetTester tester, String campo, String texto) =>
      digitar(tester, chave('valores-$campo'), texto);

  testWidgets('empresa, materiais, exemplos A e B, finalizar, rev. 2, '
      'enviar e agendar', (tester) async {
    await abrirAppVazio(tester);
    final container = containerDoApp(tester);

    // 1. Cadastros.
    await cadastrarEmpresa(tester);
    await cadastrarMateriais(tester);

    // 2. Wizard: cliente novo.
    await tocar(tester, find.text('Início'));
    await tocar(tester, find.text('Criar orçamento'));
    expect(find.byType(OrcamentoWizardPage), findsOneWidget);
    await preencherCliente(tester);
    await tocar(tester, find.text('Continuar'));

    // 3. Produtos: exemplo A (mesa) e exemplo B (painel).
    await produto(
      tester,
      descricao: 'Mesa de jantar sob medida',
      quantidade: '2',
      precoBase: '800,00',
    );
    await peca(
      tester,
      descricao: 'Tampo',
      material: 'Granito',
      comprimento: '180',
      largura: '90',
    );
    await peca(
      tester,
      descricao: 'Perna',
      material: 'Madeira',
      comprimento: '75',
      largura: '8',
      espessura: '8',
      quantidade: '4',
    );
    await tocar(tester, find.text('Adicionar produto'));
    await produto(
      tester,
      descricao: 'Painel em MDF',
      quantidade: '3',
      precoBase: '150,00',
    );
    await peca(
      tester,
      descricao: 'Painel',
      material: 'MDF',
      comprimento: '120',
      largura: '60',
    );
    await tocar(tester, find.text('Adicionar produto'));
    expect(find.text(r'R$ 2.706,40'), findsWidgets);
    expect(find.text(r'R$ 644,40'), findsWidgets);
    await tocar(tester, find.text('Continuar'));

    // 4. Valores do fechamento C.
    await valor(tester, 'insumos', '100,00');
    await valor(tester, 'impostos', '200,00');
    await valor(tester, 'combustivel', '50,00');
    await valor(tester, 'outros', '30,00');
    await valor(tester, 'outros-descricao', 'Frete');
    await valor(tester, 'desconto', '100,00');
    await tocar(tester, find.text('Continuar'));

    // 5. Prévia (D-39) e finalização.
    expect(find.textContaining('Etapa 4 de 4'), findsOneWidget);
    expect(naLinha('Total dos produtos', r'R$ 3.350,80'), findsOneWidget);
    expect(naLinha('Subtotal', r'R$ 3.730,80'), findsOneWidget);
    expect(naLinha('Total geral', r'R$ 3.630,80'), findsOneWidget);
    await tocar(tester, find.text('Finalizar'));

    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text(codigo), findsOneWidget);
    expect(naLinha('Total geral', r'R$ 3.630,80'), findsOneWidget);
    final [criado] = await container.read(orcamentosProvider.future);
    expect(criado.codigo, codigo);
    expect(criado.revisao, 1);
    expect(criado.status, StatusOrcamento.criado);
    expect(criado.totalGeral.formatado, r'R$ 3.630,80');
    expect(criado.cliente.nome, 'Maria Souza');
    expect(criado.emitente.nomeRazaoSocial, 'Serralheria Exemplo Ltda');

    // 6. Edição: desconto de R$ 130,00 grava a rev. 2.
    await tocar(tester, find.text('Editar'));
    await tocar(tester, find.text('Continuar'));
    await tocar(tester, find.text('Continuar'));
    await valor(tester, 'desconto', '130,00');
    await tocar(tester, find.text('Continuar'));
    expect(naLinha('Total geral', r'R$ 3.600,80'), findsOneWidget);
    await tocar(tester, find.text('Salvar alterações'));

    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text('$codigo rev. 2'), findsOneWidget);
    expect(naLinha('Total geral', r'R$ 3.600,80'), findsOneWidget);
    final [editado] = await container.read(orcamentosProvider.future);
    expect(editado.id, criado.id);
    expect(editado.revisao, 2);
    expect(editado.totalGeral.formatado, r'R$ 3.600,80');

    // 7. Envio pelo WhatsApp (D-29, D-37).
    await tocar(tester, find.text('Enviar WhatsApp'));
    final enviadoPeloLauncher =
        verify(() => launcher.enviarOrcamento(captureAny())).captured.single
            as Orcamento;
    expect(enviadoPeloLauncher.cliente.celular, '(51) 98888-7777');
    final [enviado] = await container.read(orcamentosProvider.future);
    expect(enviado.status, StatusOrcamento.enviado);
    expect(enviado.enviadoEm, agora);
    expect(enviado.atualizadoEm, editado.atualizadoEm);

    // 8. Agendar a produção (D-41): tarefa vinculada, com o código sem a
    // revisão.
    await tocar(tester, find.text('Agendar'));
    expect(find.text('Produção $codigo'), findsOneWidget);
    // Data e hora vêm dos seletores, abertos no "agora" (28/10, 09:00).
    await tocar(tester, chave('tarefa-data'));
    await tocar(tester, find.text('OK'));
    await tocar(tester, chave('tarefa-hora'));
    await tocar(tester, find.text('OK'));
    await tocar(tester, find.text('Salvar tarefa'));
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text('Produção $codigo'), findsOneWidget);
    final [tarefa] = await container.read(tarefasProvider.future);
    expect(tarefa.titulo, 'Produção $codigo');
    expect(tarefa.tipo, TipoTarefa.producao);
    expect(tarefa.orcamentoId, criado.id);
    expect(tarefa.data, agora);

    // A tarefa aparece na agenda, com o atalho para o orçamento.
    await tocar(tester, find.byTooltip('Voltar'));
    await tocar(tester, find.text('Agenda'));
    // O dia fica abaixo do calendário: rola a lista até a tarefa.
    await tester.scrollUntilVisible(
      find.text('Produção $codigo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Produção $codigo'), findsOneWidget);
    await tocar(tester, find.text('Ver Detalhes'));
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text('$codigo rev. 2'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
