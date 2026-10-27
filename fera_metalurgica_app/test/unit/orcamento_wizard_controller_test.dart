import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_state.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_local_json_storage.dart';

void main() {
  final agora = DateTime(2026, 10, 26, 9, 30);
  late ProviderContainer container;

  setUp(() async {
    final storage = InMemoryJsonStorage();
    await popularDadosIniciais(storage, incluirExemplos: true);
    container = ProviderContainer(
      overrides: [
        localJsonStorageProvider.overrideWithValue(storage),
        agoraProvider.overrideWithValue(agora),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Abre o wizard (mantendo o provider autoDispose vivo) e devolve o
  /// notifier já carregado.
  Future<OrcamentoWizardController> abrir({
    String? orcamentoId,
    String? produtoId,
  }) async {
    final provider = orcamentoWizardControllerProvider(
      orcamentoId: orcamentoId,
      produtoId: produtoId,
    );
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final wizard = container.read(provider.notifier);
    return wizard;
  }

  OrcamentoWizardState estado(OrcamentoWizardController wizard) =>
      wizard.state.requireValue!;

  void preencherCliente(OrcamentoWizardController wizard) =>
      wizard.atualizarCliente(
        nome: '  João da Silva ',
        numero: '(11) 98765-4321',
        cpfCnpj: '529.982.247-25',
        email: ' ',
      );

  const item = ItemOrcamento(
    id: 'item-1',
    tipoServico: 'Portão metálico basculante',
    medidas: Medidas(altura: 2.5, largura: 2.2),
  );

  group('abertura', () {
    test('novo começa vazio, na etapa 1 e sem alteração', () async {
      final wizard = await abrir();

      final atual = estado(wizard);
      expect(atual.etapa, 1);
      expect(atual.edicao, isFalse);
      expect(atual.alterado, isFalse);
      expect(atual.orcamento.itens, isEmpty);
    });

    test('vindo do catálogo, o 1º item é o produto (RF-27)', () async {
      final wizard = await abrir(produtoId: 'produto-portao-basculante');

      final itens = estado(wizard).orcamento.itens;
      expect(itens, hasLength(1));
      expect(itens.single.tipoServico, 'Portão Basculante');
      expect(itens.single.produtoId, 'produto-portao-basculante');
      expect(estado(wizard).alterado, isFalse);
    });

    test('produto inexistente é ignorado', () async {
      final wizard = await abrir(produtoId: 'p1');

      expect(estado(wizard).orcamento.itens, isEmpty);
    });

    test('edição carrega o orçamento salvo', () async {
      final wizard = await abrir(orcamentoId: '00478');

      expect(estado(wizard).edicao, isTrue);
      expect(
        estado(wizard).orcamento,
        orcamentosSeed.firstWhere((o) => o.id == '00478'),
      );
    });

    test('edição de orçamento inexistente devolve null', () async {
      final provider = orcamentoWizardControllerProvider(orcamentoId: '99999');
      container.listen(provider, (_, _) {});

      expect(await container.read(provider.future), isNull);
    });
  });

  group('validação por etapa', () {
    test('etapa 1 exige cliente válido', () async {
      final wizard = await abrir();
      expect(wizard.avancar(), isFalse);

      wizard.atualizarCliente(
        nome: 'João',
        numero: '(11) 98765-4321',
        cpfCnpj: '123.456.789-00',
      );
      expect(wizard.etapaValida(1), isFalse);

      preencherCliente(wizard);
      expect(wizard.avancar(), isTrue);
      expect(estado(wizard).etapa, 2);
    });

    test('etapa 1 rejeita e-mail inválido', () async {
      final wizard = await abrir();
      preencherCliente(wizard);
      wizard.atualizarCliente(
        nome: 'João',
        numero: '(11) 98765-4321',
        cpfCnpj: '529.982.247-25',
        email: 'joao@',
      );

      expect(wizard.etapaValida(1), isFalse);
    });

    test('etapa 2 exige pelo menos 1 item', () async {
      final wizard = await abrir();
      preencherCliente(wizard);
      wizard.avancar();

      expect(wizard.avancar(), isFalse);
      wizard.adicionarItem(item);
      expect(wizard.avancar(), isTrue);
      expect(estado(wizard).etapa, 3);
    });

    test('etapa 3 aceita total zero e a 4 é a última', () async {
      final wizard = await abrir();
      preencherCliente(wizard);
      wizard
        ..avancar()
        ..adicionarItem(item)
        ..avancar();

      expect(wizard.avancar(), isTrue);
      expect(estado(wizard).etapa, 4);
      expect(wizard.avancar(), isFalse);
    });

    test('voltar mantém os dados e para na etapa 1', () async {
      final wizard = await abrir();
      preencherCliente(wizard);
      wizard
        ..avancar()
        ..adicionarItem(item);

      expect(wizard.voltar(), isTrue);
      expect(estado(wizard).etapa, 1);
      expect(estado(wizard).orcamento.itens, [item]);
      expect(wizard.voltar(), isFalse);
    });
  });

  group('cliente', () {
    test('apara textos e transforma opcionais vazios em null', () async {
      final wizard = await abrir();
      preencherCliente(wizard);

      final cliente = estado(wizard).orcamento.cliente;
      expect(cliente.nome, 'João da Silva');
      expect(cliente.email, isNull);
      expect(cliente.observacoes, isNull);
      expect(estado(wizard).alterado, isTrue);
    });
  });

  group('itens', () {
    test('adicionar, editar e excluir', () async {
      final wizard = await abrir();
      const outro = ItemOrcamento(id: 'item-2', tipoServico: 'Grade');

      wizard
        ..adicionarItem(item)
        ..adicionarItem(outro)
        ..atualizarItem(item.copyWith(quantidade: 3));
      expect(estado(wizard).orcamento.itens, [
        item.copyWith(quantidade: 3),
        outro,
      ]);

      wizard.removerItem('item-1');
      expect(estado(wizard).orcamento.itens, [outro]);
    });
  });

  group('concluir', () {
    test('novo: próximo id, data atual, emAnalise e projeto padrão', () async {
      final wizard = await abrir();
      preencherCliente(wizard);
      wizard
        ..adicionarItem(item)
        ..atualizarCustos(
          const CustosOperacionais(
            materiaPrima: 2450,
            maoDeObra: 1800,
            insumos: 350,
            combustivel: 180,
            impostos: 420,
          ),
        );

      final id = await wizard.concluir();

      expect(id, '00483');
      final salvo = await container.read(orcamentoPorIdProvider(id).future);
      expect(salvo, isNotNull);
      expect(salvo!.criadoEm, agora);
      expect(salvo.status, StatusOrcamento.emAnalise);
      expect(salvo.projeto, 'Portão metálico basculante');
      expect(salvo.valorFinal, 8450);
      expect(container.read(orcamentosProvider).value!.first.id, '00483');
    });

    test('novo: mantém o nome do projeto digitado', () async {
      final wizard = await abrir();
      preencherCliente(wizard);
      wizard
        ..atualizarProjeto('  Portão da garagem ')
        ..adicionarItem(item);

      final id = await wizard.concluir();

      final salvo = await container.read(orcamentoPorIdProvider(id).future);
      expect(salvo!.projeto, 'Portão da garagem');
    });

    test('edição preserva id, criadoEm e status', () async {
      final original = orcamentosSeed.firstWhere((o) => o.id == '00478');
      final wizard = await abrir(orcamentoId: '00478');
      wizard.atualizarCustos(const CustosOperacionais(maoDeObra: 100));

      final id = await wizard.concluir();

      expect(id, '00478');
      final salvo = await container.read(orcamentoPorIdProvider(id).future);
      expect(salvo!.criadoEm, original.criadoEm);
      expect(salvo.status, original.status);
      expect(salvo.custosOperacionais.maoDeObra, 100);
      expect(
        container.read(orcamentosProvider).value!.where((o) => o.id == id),
        hasLength(1),
      );
    });

    test('recusa orçamento incompleto', () async {
      final wizard = await abrir();
      preencherCliente(wizard);

      expect(wizard.concluir, throwsStateError);
    });
  });
}
