import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/container_de_teste.dart';
import '../../../mocks/mock_cep_repository.dart';
import '../../../mocks/mock_localizacao_repository.dart';
import 'wizard_teste_helpers.dart';

/// CPF válido que nenhum cliente de exemplo usa.
const String _cpfNovo = '111.444.777-35';

/// Etapa 1 (prompt §3.3) sobre os dados de exemplo: os clientes João da
/// Silva (CPF 529.982.247-25) e Construtora Horizonte Ltda (CNPJ
/// 11.222.333/0001-81), e os orçamentos C (de João) e B. "Agora" é
/// 26/10/2026, 10h.
void main() {
  final agora = DateTime(2026, 10, 26, 10);
  late List<Override> overrides;
  late Orcamento c;

  setUp(() async {
    overrides = await overridesDeTeste(agora: agora);
    c = (await orcamentosGravados(overrides)).last;
  });

  Future<List<Cliente>> clientesCadastrados() async {
    final container = ProviderContainer(overrides: overrides);
    try {
      return await container.read(clienteRepositoryProvider).pesquisar('');
    } finally {
      container.dispose();
    }
  }

  Finder campo(String nome) => find.descendant(
    of: find.byKey(ValueKey('cliente-$nome')),
    matching: find.byType(EditableText),
  );

  String texto(WidgetTester tester, String nome) =>
      tester.widget<EditableText>(campo(nome)).controller.text;

  Future<void> digitar(WidgetTester tester, String nome, String valor) async {
    await tester.ensureVisible(campo(nome));
    await tester.enterText(campo(nome), valor);
    await tester.pumpAndSettle();
  }

  Future<void> buscar(WidgetTester tester, String termo) async {
    await tester.enterText(
      find.byKey(const ValueKey('wizard-busca-cliente')),
      termo,
    );
    await tester.pumpAndSettle();
  }

  Finder resultado(String nome) => find.descendant(
    of: find.byKey(const ValueKey('wizard-resultados-cliente')),
    matching: find.text(nome),
  );

  /// Abre [rota] (o wizard novo ou a edição de C) com `abrirWizard`.
  Future<void> abrir(
    WidgetTester tester,
    String rota, {
    ThemeMode themeMode = ThemeMode.light,
    Size tamanho = const Size(800, 2400),
  }) => abrirWizard(
    tester,
    rota,
    overrides: overrides,
    themeMode: themeMode,
    tamanho: tamanho,
  );

  /// Da etapa 1 da edição até salvar, sem mexer nas outras etapas.
  Future<Orcamento> salvarEdicao(WidgetTester tester) async {
    await tocar(tester, continuar);
    await tocar(tester, continuar);
    await tocar(tester, continuar);
    await tocar(tester, find.text('Salvar alterações'));
    return (await orcamentosGravados(overrides)).first;
  }

  group('busca', () {
    testWidgets('sem termo, não lista ninguém', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento());

      expect(
        find.byKey(const ValueKey('wizard-resultados-cliente')),
        findsNothing,
      );
      expect(find.text('João da Silva'), findsNothing);
    });

    testWidgets('acha por nome, celular e documento', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento());

      await buscar(tester, 'horizonte');
      expect(resultado('Construtora Horizonte Ltda'), findsOneWidget);
      expect(resultado('João da Silva'), findsNothing);

      await buscar(tester, '99999-8888');
      expect(resultado('João da Silva'), findsOneWidget);

      await buscar(tester, '11222333');
      expect(resultado('Construtora Horizonte Ltda'), findsOneWidget);
    });

    testWidgets('sem resultado, convida a preencher', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento());

      await buscar(tester, 'ninguém com este nome');

      expect(find.textContaining('Nenhum cliente encontrado'), findsOneWidget);
    });

    testWidgets('selecionar preenche a cópia editável e limpa a busca', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.novoOrcamento());
      await buscar(tester, 'Construtora');

      await tocar(tester, resultado('Construtora Horizonte Ltda'));

      expect(texto(tester, 'nome'), 'Construtora Horizonte Ltda');
      expect(texto(tester, 'documento'), '11.222.333/0001-81');
      expect(texto(tester, 'celular'), '(11) 98888-7777');
      expect(texto(tester, 'logradouro'), 'Av. Paulista');
      expect(texto(tester, 'complemento'), 'Sala 12');
      expect(texto(tester, 'uf'), 'SP');
      expect(
        find.byKey(const ValueKey('wizard-resultados-cliente')),
        findsNothing,
      );

      await tocar(tester, continuar);
      expect(find.text('Etapa 2 de 4: Produtos'), findsOneWidget);
    });
  });

  testWidgets('cliente existente: salvar não cria outro cadastro', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await preencherStub(tester, cliente: 'Construtora Horizonte Ltda');

    await tocar(tester, find.text('Finalizar'));

    final novo = (await orcamentosGravados(overrides)).first;
    expect(novo.cliente.nome, 'Construtora Horizonte Ltda');
    expect(await clientesCadastrados(), hasLength(2));
  });

  testWidgets('sem os obrigatórios, mostra o erro em cada campo', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.novoOrcamento());

    await tocar(tester, continuar);
    expect(
      find.text('Busque um cliente cadastrado ou preencha os dados abaixo.'),
      findsOneWidget,
    );

    await digitar(tester, 'nome', 'Maria Souza');
    await digitar(tester, 'documento', '123');
    await digitar(tester, 'uf', 'sp');
    expect(texto(tester, 'uf'), 'SP');
    await tocar(tester, continuar);

    expect(find.text('Etapa 1 de 4: Cliente'), findsOneWidget);
    for (final nome in [
      'celular',
      'logradouro',
      'numero',
      'bairro',
      'cidade',
    ]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('cliente-$nome')),
          matching: find.text('Campo obrigatório'),
        ),
        findsOneWidget,
        reason: nome,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cliente-documento')),
        matching: find.textContaining('11 dígitos'),
      ),
      findsOneWidget,
    );
  });

  group('consulta do CEP (D-43)', () {
    late MockCepRepository cep;

    setUp(() {
      cep = MockCepRepository();
      overrides = [...overrides, cepRepositoryProvider.overrideWithValue(cep)];
    });

    testWidgets('com 8 dígitos, preenche o endereço e mantém o número', (
      tester,
    ) async {
      when(() => cep.buscar('01001000')).thenAnswer(
        (_) async => const EnderecoEncontrado(
          logradouro: 'Praça da Sé',
          bairro: 'Sé',
          cidade: 'São Paulo',
          uf: 'SP',
        ),
      );
      await abrir(tester, AppRoutes.novoOrcamento());
      await digitar(tester, 'numero', '100');

      await digitar(tester, 'cep', '0100100');
      verifyNever(() => cep.buscar(any()));
      await digitar(tester, 'cep', '01001000');

      expect(texto(tester, 'logradouro'), 'Praça da Sé');
      expect(texto(tester, 'bairro'), 'Sé');
      expect(texto(tester, 'cidade'), 'São Paulo');
      expect(texto(tester, 'uf'), 'SP');
      expect(texto(tester, 'numero'), '100');
      expect(texto(tester, 'cep'), '01001-000');
    });

    testWidgets('CEP geral não apaga o logradouro já digitado', (tester) async {
      when(() => cep.buscar(any())).thenAnswer(
        (_) async => const EnderecoEncontrado(cidade: 'Arroio', uf: 'RS'),
      );
      await abrir(tester, AppRoutes.novoOrcamento());
      await digitar(tester, 'logradouro', 'Rua A');

      await digitar(tester, 'cep', '95000000');

      expect(texto(tester, 'logradouro'), 'Rua A');
      expect(texto(tester, 'cidade'), 'Arroio');
    });

    testWidgets('CEP inexistente avisa e não muda o endereço', (tester) async {
      when(() => cep.buscar(any())).thenAnswer((_) async => null);
      await abrir(tester, AppRoutes.novoOrcamento());

      await digitar(tester, 'cep', '99999999');

      expect(
        find.text('CEP não encontrado. Preencha o endereço.'),
        findsOneWidget,
      );
      expect(texto(tester, 'cidade'), isEmpty);
    });

    testWidgets('sem internet, avisa e deixa digitar à mão', (tester) async {
      when(() => cep.buscar(any())).thenThrow(Exception('sem internet'));
      await abrir(tester, AppRoutes.novoOrcamento());

      await digitar(tester, 'cep', '01001000');

      expect(
        find.text('Não foi possível consultar o CEP. Preencha o endereço.'),
        findsOneWidget,
      );
    });

    testWidgets('abrir um orçamento salvo não consulta o CEP', (tester) async {
      await abrir(tester, AppRoutes.editarOrcamento(c.id));

      verifyNever(() => cep.buscar(any()));
    });
  });

  group('"Usar minha localização" (D-43)', () {
    late MockLocalizacaoRepository localizacao;
    final botao = find.byKey(const ValueKey('cliente-usar-localizacao'));

    setUp(() {
      localizacao = MockLocalizacaoRepository();
      overrides = [
        ...overrides,
        localizacaoRepositoryProvider.overrideWithValue(localizacao),
      ];
    });

    Future<void> tocarNoBotao(WidgetTester tester) async {
      await tester.ensureVisible(botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();
    }

    testWidgets('preenche o endereço e deixa o número para o operador', (
      tester,
    ) async {
      when(localizacao.enderecoAtual).thenAnswer(
        (_) async => const EnderecoEncontrado(
          logradouro: 'Avenida Ipiranga',
          bairro: 'Azenha',
          cidade: 'Porto Alegre',
          uf: 'RS',
          cep: '90160093',
        ),
      );
      await abrir(tester, AppRoutes.novoOrcamento());

      await tocarNoBotao(tester);

      expect(texto(tester, 'logradouro'), 'Avenida Ipiranga');
      expect(texto(tester, 'bairro'), 'Azenha');
      expect(texto(tester, 'cidade'), 'Porto Alegre');
      expect(texto(tester, 'uf'), 'RS');
      expect(texto(tester, 'cep'), '90160-093');
      expect(texto(tester, 'numero'), isEmpty);
      expect(
        find.text('Confira o endereço e informe o número.'),
        findsOneWidget,
      );
    });

    testWidgets('campo que não veio fica como está', (tester) async {
      when(localizacao.enderecoAtual).thenAnswer(
        (_) async => const EnderecoEncontrado(cidade: 'Canoas', uf: 'RS'),
      );
      await abrir(tester, AppRoutes.novoOrcamento());
      await digitar(tester, 'bairro', 'Centro');

      await tocarNoBotao(tester);

      expect(texto(tester, 'bairro'), 'Centro');
      expect(texto(tester, 'cidade'), 'Canoas');
      expect(texto(tester, 'cep'), isEmpty);
    });

    for (final (motivo, mensagem) in const [
      (
        MotivoFalhaLocalizacao.indisponivel,
        'A localização só funciona no celular.',
      ),
      (
        MotivoFalhaLocalizacao.gpsDesligado,
        'Ligue a localização do celular e tente de novo.',
      ),
      (
        MotivoFalhaLocalizacao.semPermissao,
        'Libere a localização para o app nas configurações do celular.',
      ),
      (
        MotivoFalhaLocalizacao.semEndereco,
        'Nenhum endereço encontrado aqui. Preencha à mão.',
      ),
    ]) {
      testWidgets('${motivo.name} mostra o aviso', (tester) async {
        when(localizacao.enderecoAtual).thenThrow(FalhaLocalizacao(motivo));
        await abrir(tester, AppRoutes.novoOrcamento());

        await tocarNoBotao(tester);

        expect(find.text(mensagem), findsOneWidget);
        expect(texto(tester, 'cidade'), isEmpty);
      });
    }

    testWidgets('outro erro mostra o aviso genérico', (tester) async {
      when(localizacao.enderecoAtual).thenThrow(Exception('falhou'));
      await abrir(tester, AppRoutes.novoOrcamento());

      await tocarNoBotao(tester);

      expect(
        find.text('Não foi possível obter a localização. Preencha o endereço.'),
        findsOneWidget,
      );
    });
  });

  group('edição do exemplo C (cliente João da Silva)', () {
    testWidgets('abre com a cópia do cliente e sem aviso', (tester) async {
      await abrir(tester, AppRoutes.editarOrcamento(c.id));

      expect(texto(tester, 'nome'), 'João da Silva');
      expect(texto(tester, 'documento'), '529.982.247-25');
      expect(texto(tester, 'cep'), '01455-000');
      expect(
        find.byKey(const ValueKey('cliente-aviso-outro-cadastro')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cliente-aviso-cadastro-novo')),
        findsNothing,
      );
    });

    testWidgets('editar a cópia atualiza o mesmo cadastro ao salvar', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.editarOrcamento(c.id));
      await digitar(tester, 'celular', '11977776666');

      final salvo = await salvarEdicao(tester);

      expect(salvo.cliente.celular, '(11) 97777-6666');
      final clientes = await clientesCadastrados();
      expect(clientes, hasLength(2));
      final joao = clientes.firstWhere((x) => x.nome == 'João da Silva');
      expect(joao.celular, '(11) 97777-6666');
      expect(salvo.cliente.clienteOrigemId, joao.id);
    });

    testWidgets('documento novo avisa e cria outro cadastro ao salvar', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.editarOrcamento(c.id));
      await digitar(tester, 'nome', 'Maria Souza');
      await digitar(tester, 'documento', _cpfNovo);

      final aviso = find.byKey(const ValueKey('cliente-aviso-cadastro-novo'));
      expect(aviso, findsOneWidget);
      expect(
        find.descendant(
          of: aviso,
          matching: find.textContaining('João da Silva'),
        ),
        findsOneWidget,
      );

      final salvo = await salvarEdicao(tester);

      final clientes = await clientesCadastrados();
      expect(clientes, hasLength(3));
      final maria = clientes.firstWhere((x) => x.nome == 'Maria Souza');
      expect(maria.documento, Documento.deTexto(_cpfNovo));
      expect(salvo.cliente.clienteOrigemId, maria.id);
      // O cadastro de João não muda.
      expect(clientes.where((x) => x.nome == 'João da Silva'), hasLength(1));
    });

    testWidgets('documento de outro cadastro avisa e oferece usá-lo', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.editarOrcamento(c.id));
      await digitar(tester, 'documento', '11.222.333/0001-81');

      final aviso = find.byKey(const ValueKey('cliente-aviso-outro-cadastro'));
      expect(aviso, findsOneWidget);
      expect(
        find.descendant(
          of: aviso,
          matching: find.textContaining('Construtora Horizonte Ltda'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: aviso,
          matching: find.textContaining('serão atualizados'),
        ),
        findsOneWidget,
      );
      // Não troca os dados sozinho.
      expect(texto(tester, 'nome'), 'João da Silva');

      await tocar(tester, find.text('Usar cadastro'));

      expect(texto(tester, 'nome'), 'Construtora Horizonte Ltda');
      expect(texto(tester, 'complemento'), 'Sala 12');
      expect(aviso, findsNothing);
      final salvo = await salvarEdicao(tester);
      expect(salvo.cliente.nome, 'Construtora Horizonte Ltda');
      expect(await clientesCadastrados(), hasLength(2));
    });

    testWidgets('voltar ao documento original tira o aviso', (tester) async {
      await abrir(tester, AppRoutes.editarOrcamento(c.id));
      await digitar(tester, 'documento', _cpfNovo);
      expect(
        find.byKey(const ValueKey('cliente-aviso-cadastro-novo')),
        findsOne,
      );

      await digitar(tester, 'documento', '52998224725');

      expect(
        find.byKey(const ValueKey('cliente-aviso-cadastro-novo')),
        findsNothing,
      );
    });
  });

  testWidgets('voltar da etapa 2 mantém o cliente', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await buscar(tester, 'João');
    await tocar(tester, resultado('João da Silva'));
    await digitar(tester, 'complemento', 'Casa 2');
    await tocar(tester, continuar);

    await tocar(tester, find.text('Voltar'));

    expect(texto(tester, 'nome'), 'João da Silva');
    expect(texto(tester, 'complemento'), 'Casa 2');
  });

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('360 dp com aviso, sem transbordar (${modo.name})', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await abrir(
        tester,
        AppRoutes.editarOrcamento(c.id),
        themeMode: modo,
        tamanho: const Size(360, 640),
      );
      await digitar(tester, 'documento', '11.222.333/0001-81');
      await buscar(tester, 'Silva');

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  }
}
