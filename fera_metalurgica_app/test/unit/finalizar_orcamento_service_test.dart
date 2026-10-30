import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_unidade_de_trabalho.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/finalizar_orcamento_service.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

void main() {
  late Database banco;
  late SqliteOrcamentoRepository orcamentos;
  late SqliteClienteRepository clientes;
  late FinalizarOrcamentoService servico;
  late DateTime agora;
  late int ids;

  setUp(() async {
    banco = await bancoDeTeste();
    orcamentos = SqliteOrcamentoRepository(banco);
    clientes = SqliteClienteRepository(banco);
    agora = DateTime(2026, 10, 28, 14, 30);
    ids = 0;
    servico = FinalizarOrcamentoService(
      unidadeDeTrabalho: SqliteUnidadeDeTrabalho(banco),
      relogio: () => agora,
      gerarId: () => 'id-${ids++}',
    );
  });
  tearDown(() => banco.close());

  /// [edicao] com chave e ids de itens e peças novos, como uma sessão nova.
  OrcamentoEmEdicao nova(OrcamentoEmEdicao edicao, String chave) =>
      edicao.copyWith(
        chaveFinalizacao: chave,
        itens: [
          for (final item in edicao.itens)
            item.duplicarComNovosIds(() => '$chave-${ids++}'),
        ],
      );

  /// Sessão de edição de [salvo], como `iniciarEdicao` montaria.
  OrcamentoEmEdicao editar(Orcamento salvo, String chave) => OrcamentoEmEdicao(
    chaveFinalizacao: chave,
    emitente: salvo.emitente,
    cliente: salvo.cliente,
    itens: salvo.itens,
    insumos: salvo.insumos,
    impostos: salvo.impostos,
    combustivel: salvo.combustivel,
    outros: salvo.outros,
    outrosDescricao: salvo.outrosDescricao,
    desconto: salvo.desconto,
    validadeDias: salvo.validadeDias,
    observacoes: salvo.observacoes,
    orcamentoOrigemId: salvo.id,
    codigo: salvo.codigo,
    revisao: salvo.revisao,
  );

  group('criação', () {
    test('grava o exemplo C com código do dia, revisão 1 e criado', () async {
      final salvo = await servico.executar(edicaoC);

      expect(salvo.codigo, '281026-01');
      expect(salvo.codigoExibicao, '281026-01');
      expect(salvo.revisao, 1);
      expect(salvo.status, StatusOrcamento.criado);
      expect(salvo.enviadoEm, isNull);
      expect(salvo.criadoEm, agora);
      expect(salvo.atualizadoEm, agora);
      expect(salvo.totalGeral, Dinheiro.parse('3.630,80'));
      expect(salvo.versaoCalculo, 1);
      expect(await orcamentos.buscarPorId(salvo.id), salvo);
    });

    test('o próximo do dia é -02; no dia seguinte volta a -01', () async {
      await servico.executar(nova(edicaoB, 'k1'));
      expect((await servico.executar(nova(edicaoB, 'k2'))).codigo, '281026-02');

      agora = DateTime(2026, 10, 29, 0, 0, 1);
      expect((await servico.executar(nova(edicaoB, 'k3'))).codigo, '291026-01');
    });

    test('cria o cadastro do cliente e guarda a origem na cópia', () async {
      final copia = clienteTeste.gerarSnapshot().copyWith(
        clienteOrigemId: null,
      );
      final salvo = await servico.executar(edicaoB.copyWith(cliente: copia));

      final cadastro = await clientes.buscarPorDocumento(copia.documento);
      expect(cadastro, isNotNull);
      expect(cadastro!.nome, copia.nome);
      expect(salvo.cliente.clienteOrigemId, cadastro.id);
    });

    test(
      'cliente já cadastrado pelo documento é atualizado, não duplicado',
      () async {
        await clientes.salvar(clienteTeste);
        final copia = clienteTeste.gerarSnapshot().copyWith(
          nome: 'João da Silva Jr.',
          clienteOrigemId: null,
        );

        final salvo = await servico.executar(edicaoB.copyWith(cliente: copia));

        expect(await clientes.pesquisar(''), [
          clienteTeste.copyWith(nome: 'João da Silva Jr.'),
        ]);
        expect(salvo.cliente.clienteOrigemId, clienteTeste.id);
      },
    );
  });

  group('idempotência pela chave', () {
    test('repetir a mesma chave devolve o mesmo orçamento', () async {
      final primeiro = await servico.executar(edicaoC);
      final segundo = await servico.executar(edicaoC);

      expect(segundo, primeiro);
      expect(await orcamentos.listarResumos(), hasLength(1));
    });

    test('clique duplo simultâneo grava um só e não gasta sequência', () async {
      final resultados = await Future.wait([
        servico.executar(edicaoC),
        servico.executar(edicaoC),
      ]);

      expect(resultados.first, resultados.last);
      expect(await orcamentos.listarResumos(), hasLength(1));
      expect((await servico.executar(nova(edicaoB, 'k'))).codigo, '281026-02');
    });
  });

  group('edição (D-30)', () {
    test('grava a rev. 2 no lugar, com o mesmo código e criadoEm', () async {
      final original = await servico.executar(edicaoC);
      agora = DateTime(2026, 10, 30, 9);

      final edicao = editar(
        original,
        'chave-edicao',
      ).copyWith(desconto: Dinheiro.zero);
      final revisado = await servico.executar(edicao);

      expect(revisado.id, original.id);
      expect(revisado.codigo, original.codigo);
      expect(revisado.criadoEm, original.criadoEm);
      expect(revisado.revisao, 2);
      expect(revisado.codigoExibicao, '281026-01 rev. 2');
      expect(revisado.atualizadoEm, agora);
      expect(revisado.totalGeral, Dinheiro.parse('3.730,80'));
      expect(await orcamentos.listarResumos(), [revisado]);
    });

    test('a chave da edição substitui a anterior na mesma linha', () async {
      final original = await servico.executar(edicaoC);
      final revisado = await servico.executar(editar(original, 'chave-ed'));

      expect(await orcamentos.buscarPorChaveFinalizacao('chave-ed'), revisado);
      expect(
        await orcamentos.buscarPorChaveFinalizacao(edicaoC.chaveFinalizacao),
        isNull,
      );
    });

    test('clique duplo na edição não gera a rev. 3', () async {
      final original = await servico.executar(edicaoC);
      final edicao = editar(original, 'chave-ed');

      final primeiro = await servico.executar(edicao);
      final segundo = await servico.executar(edicao);

      expect(segundo, primeiro);
      expect(segundo.revisao, 2);
    });

    test('um orçamento enviado volta para criado, sem enviadoEm', () async {
      final original = await servico.executar(edicaoC);
      final enviado = original.copyWith(
        status: StatusOrcamento.enviado,
        enviadoEm: DateTime(2026, 10, 29),
      );
      await orcamentos.atualizar(enviado);

      final revisado = await servico.executar(editar(enviado, 'chave-ed'));

      expect(revisado.status, StatusOrcamento.criado);
      expect(revisado.enviadoEm, isNull);
    });

    test('editar um orçamento excluído falha sem gravar', () async {
      final original = await servico.executar(edicaoC);
      await orcamentos.excluir(original.id);

      await expectLater(
        servico.executar(editar(original, 'chave-ed')),
        throwsA(isA<StateError>()),
      );
      expect(await orcamentos.listarResumos(), isEmpty);
    });
  });

  group('validação e transação', () {
    test('edição inválida não grava nada nem gasta sequência', () async {
      final semItens = edicaoC.copyWith(itens: []);
      await expectLater(
        servico.executar(semItens),
        throwsA(
          isA<OrcamentoInvalidoException>().having(
            (e) => e.erros.map((erro) => erro.caminhoCampo),
            'campos',
            contains('itens'),
          ),
        ),
      );

      final descontoAlto = edicaoB.copyWith(desconto: Dinheiro.parse('1.000'));
      await expectLater(
        servico.executar(descontoAlto),
        throwsA(isA<OrcamentoInvalidoException>()),
      );

      expect(await orcamentos.listarResumos(), isEmpty);
      expect(await clientes.pesquisar(''), isEmpty);
      expect((await servico.executar(edicaoB)).codigo, '281026-01');
    });

    test('falha na gravação desfaz cliente e sequência', () async {
      // Um orçamento já ocupa o código que seria gerado: o inserir falha.
      await orcamentos.inserir(
        orcamentoSalvo(
          nova(edicaoB, 'antigo'),
          id: 'antigo',
          codigo: '281026-01',
        ),
      );
      final copia = clienteTeste.gerarSnapshot().copyWith(
        documento: Documento.deTexto('11222333000181'),
      );

      await expectLater(
        servico.executar(nova(edicaoB, 'novo').copyWith(cliente: copia)),
        throwsA(isA<DatabaseException>()),
      );

      expect(await orcamentos.listarResumos(), hasLength(1));
      expect(await clientes.buscarPorDocumento(copia.documento), isNull);
      final sequencia = await banco.query('sequencias');
      expect(sequencia, isEmpty);
    });
  });
}
