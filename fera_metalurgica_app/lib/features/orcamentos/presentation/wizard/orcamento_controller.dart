import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/finalizar_orcamento_service_provider.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/finalizar_orcamento_service.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/validacao_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orcamento_controller.g.dart';

/// Campos validados em cada etapa ao avançar.
const Map<int, List<String>> _camposPorEtapa = {
  1: ['cliente'],
  2: ['itens'],
  3: [
    'insumos',
    'impostos',
    'combustivel',
    'outros',
    'outrosDescricao',
    'desconto',
    'validadeDias',
  ],
};

/// Campos que precisam estar válidos para o resumo ser calculado.
const List<String> _camposDoResumo = [
  'itens',
  'insumos',
  'impostos',
  'combustivel',
  'outros',
  'desconto',
];

bool _pertence(ErroValidacao erro, List<String> campos) => campos.any(
  (campo) =>
      erro.caminhoCampo == campo ||
      erro.caminhoCampo.startsWith('$campo.') ||
      erro.caminhoCampo.startsWith('$campo['),
);

/// Estado da edição de um orçamento, compartilhado pelas 4 etapas do
/// wizard (D-28; o `OrcamentoController` do prompt §7, em Riverpod).
///
/// Guarda a sessão (`OrcamentoEmEdicao`), a etapa, o resumo, os erros e se
/// está gravando. Não tem fórmulas (são da `CalculadoraOrcamento`) nem SQL
/// (é dos repositórios); gravar é do `FinalizarOrcamentoService`.
///
/// Peças e produtos só entram na sessão depois de validados: as operações
/// de item e de peça devolvem os erros (lista vazia = aceito) e também os
/// deixam em `erros`. Durante a gravação (`finalizando`), nada muda.
///
/// Congelado depois da F2: operações novas vão por handoff (orquestracao
/// §9).
@riverpod
class OrcamentoController extends _$OrcamentoController {
  @override
  EstadoEdicaoOrcamento build() => const EstadoEdicaoOrcamento();

  OrcamentoEmEdicao get _edicao {
    final edicao = state.edicao;
    if (edicao == null) {
      throw StateError('Nenhum orçamento em edição: chame iniciar() antes');
    }
    return edicao;
  }

  // ---------------------------------------------------------------------
  // Sessão

  /// Começa um orçamento novo, com a cópia da empresa cadastrada e uma
  /// chave de finalização nova. Lança [StateError] sem empresa completa
  /// (a rota do wizard já leva a "Dados da empresa" antes).
  Future<void> iniciar() async {
    final emitente = await _emitenteAtual();
    state = EstadoEdicaoOrcamento(
      edicao: OrcamentoEmEdicao(
        chaveFinalizacao: gerarId(),
        emitente: emitente,
      ),
    );
  }

  /// Abre o orçamento salvo [orcamentoId] para edição (D-30): a sessão é uma
  /// cópia dele, com uma chave nova e a cópia ATUAL da empresa. Lança
  /// [StateError] se o orçamento não existir ou sem empresa completa.
  Future<void> iniciarEdicao(String orcamentoId) async {
    final emitente = await _emitenteAtual();
    final salvo = await ref
        .read(orcamentoRepositoryV2Provider)
        .buscarPorId(orcamentoId);
    if (salvo == null) {
      throw StateError('Orçamento $orcamentoId não encontrado');
    }
    _definir(
      OrcamentoEmEdicao(
        chaveFinalizacao: gerarId(),
        emitente: emitente,
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
      ),
      etapa: 1,
    );
  }

  /// Descarta a sessão. A interface pede a confirmação antes.
  void descartar() => state = const EstadoEdicaoOrcamento();

  // ---------------------------------------------------------------------
  // Etapa 1: cliente

  /// Preenche a cópia editável com o cliente [cliente] do cadastro.
  void selecionarCliente(Cliente cliente) =>
      atualizarCliente(cliente.gerarSnapshot());

  /// Troca a cópia do cliente na sessão. O cadastro só muda ao finalizar.
  void atualizarCliente(ClienteSnapshot cliente) {
    if (state.finalizando) return;
    _definir(_edicao.copyWith(cliente: cliente));
  }

  // ---------------------------------------------------------------------
  // Etapa 2: produtos

  /// Adiciona o produto [item] ao fim da lista, se for válido.
  List<ErroValidacao> adicionarItem(ItemOrcamento item) {
    final itens = _edicao.itens;
    return _alterarItens([
      ...itens,
      item,
    ], validarItem(item, caminho: 'itens[${itens.length}]'));
  }

  /// Substitui o produto de mesmo id por [item], se for válido.
  List<ErroValidacao> editarItem(ItemOrcamento item) {
    final indice = _indiceItem(item.id);
    return _alterarItens(
      [..._edicao.itens]..[indice] = item,
      validarItem(item, caminho: 'itens[$indice]'),
    );
  }

  /// Remove o produto [itemId].
  void removerItem(String itemId) {
    _indiceItem(itemId);
    _alterarItens([
      for (final item in _edicao.itens)
        if (item.id != itemId) item,
    ], const []);
  }

  /// Duplica o produto [itemId] logo depois dele, com ids novos no item e
  /// nas peças (cópia profunda).
  void duplicarItem(String itemId) {
    final indice = _indiceItem(itemId);
    final copia = _edicao.itens[indice].duplicarComNovosIds(gerarId);
    _alterarItens([..._edicao.itens]..insert(indice + 1, copia), const []);
  }

  // ---------------------------------------------------------------------
  // Composição do produto: peças

  /// Adiciona [peca] ao fim das peças do produto [itemId], se for válida.
  List<ErroValidacao> adicionarPeca(String itemId, PecaOrcamento peca) {
    final indice = _indiceItem(itemId);
    final item = _edicao.itens[indice];
    return _alterarPecas(
      indice,
      [...item.pecas, peca],
      validarPeca(peca, caminho: 'itens[$indice].pecas[${item.pecas.length}]'),
    );
  }

  /// Substitui a peça de mesmo id no produto [itemId], se for válida.
  List<ErroValidacao> editarPeca(String itemId, PecaOrcamento peca) {
    final indice = _indiceItem(itemId);
    final pecas = _edicao.itens[indice].pecas;
    final indicePeca = _indicePeca(pecas, peca.id);
    return _alterarPecas(
      indice,
      [...pecas]..[indicePeca] = peca,
      validarPeca(peca, caminho: 'itens[$indice].pecas[$indicePeca]'),
    );
  }

  /// Remove a peça [pecaId] do produto [itemId]. A última peça não sai: o
  /// produto precisa de pelo menos uma (remova o produto).
  List<ErroValidacao> removerPeca(String itemId, String pecaId) {
    final indice = _indiceItem(itemId);
    final pecas = _edicao.itens[indice].pecas;
    _indicePeca(pecas, pecaId);
    final restantes = [
      for (final peca in pecas)
        if (peca.id != pecaId) peca,
    ];
    return _alterarPecas(indice, restantes, [
      if (restantes.isEmpty)
        ErroValidacao(
          caminhoCampo: 'itens[$indice].pecas',
          codigo: CodigoErroValidacao.vazio,
          mensagem: 'O produto precisa de pelo menos uma peça',
        ),
    ]);
  }

  /// Duplica a peça [pecaId] logo depois dela, com id novo.
  void duplicarPeca(String itemId, String pecaId) {
    final indice = _indiceItem(itemId);
    final pecas = _edicao.itens[indice].pecas;
    final indicePeca = _indicePeca(pecas, pecaId);
    _alterarPecas(
      indice,
      [...pecas]..insert(indicePeca + 1, pecas[indicePeca].duplicar(gerarId())),
      const [],
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 3: valores

  /// Troca os valores da etapa 3 de uma vez (o estado completo do
  /// formulário). A validação acontece ao avançar e ao finalizar.
  void atualizarValores({
    required Dinheiro insumos,
    required Dinheiro impostos,
    required Dinheiro combustivel,
    required Dinheiro outros,
    required Dinheiro desconto,
    String? outrosDescricao,
    int? validadeDias,
    String? observacoes,
  }) {
    if (state.finalizando) return;
    _definir(
      _edicao.copyWith(
        insumos: insumos,
        impostos: impostos,
        combustivel: combustivel,
        outros: outros,
        outrosDescricao: outrosDescricao,
        desconto: desconto,
        validadeDias: validadeDias,
        observacoes: observacoes,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Navegação e gravação

  /// Valida a etapa atual e, se estiver tudo certo, vai para a próxima.
  /// Devolve se avançou. Na última etapa, não avança (use [finalizar]).
  bool avancar() {
    if (state.finalizando) return false;
    final etapa = state.etapaAtual;
    if (etapa >= EstadoEdicaoOrcamento.totalEtapas) return false;
    final erros = validarOrcamento(
      _edicao,
    ).where((e) => _pertence(e, _camposPorEtapa[etapa]!)).toList();
    if (erros.isNotEmpty) {
      state = state.copyWith(erros: erros);
      return false;
    }
    state = state.copyWith(etapaAtual: etapa + 1, erros: const []);
    return true;
  }

  /// Volta uma etapa, sem perder dados.
  void voltar() {
    if (state.finalizando || state.etapaAtual <= 1) return;
    state = state.copyWith(etapaAtual: state.etapaAtual - 1, erros: const []);
  }

  /// Grava a sessão pelo `FinalizarOrcamentoService` e devolve o orçamento
  /// salvo. Só depois do sucesso limpa a sessão.
  ///
  /// - Durante uma gravação, uma nova chamada devolve `null` sem gravar.
  /// - Com a sessão inválida, devolve `null` e deixa os erros em `erros`.
  /// - Se a gravação falhar, mantém a sessão e relança o erro, para a
  ///   interface avisar e permitir tentar de novo.
  Future<Orcamento?> finalizar() async {
    if (state.finalizando) return null;
    final edicao = _edicao;
    state = state.copyWith(finalizando: true, erros: const []);
    try {
      final salvo = await ref
          .read(finalizarOrcamentoServiceProvider)
          .executar(edicao);
      state = const EstadoEdicaoOrcamento();
      return salvo;
    } on OrcamentoInvalidoException catch (e) {
      state = state.copyWith(finalizando: false, erros: e.erros);
      return null;
    } catch (_) {
      state = state.copyWith(finalizando: false);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Internos

  Future<EmpresaSnapshot> _emitenteAtual() async {
    final empresa = await ref.read(empresaRepositoryProvider).obter();
    if (empresa == null || !empresa.estaCompleta) {
      throw StateError('Cadastre os dados da empresa antes do orçamento');
    }
    return empresa.gerarSnapshot();
  }

  int _indiceItem(String itemId) {
    final indice = _edicao.itens.indexWhere((i) => i.id == itemId);
    if (indice < 0) throw ArgumentError.value(itemId, 'itemId', 'não existe');
    return indice;
  }

  int _indicePeca(List<PecaOrcamento> pecas, String pecaId) {
    final indice = pecas.indexWhere((p) => p.id == pecaId);
    if (indice < 0) throw ArgumentError.value(pecaId, 'pecaId', 'não existe');
    return indice;
  }

  List<ErroValidacao> _alterarItens(
    List<ItemOrcamento> itens,
    List<ErroValidacao> erros,
  ) {
    if (state.finalizando) return const [];
    if (erros.isNotEmpty) {
      state = state.copyWith(erros: erros);
      return erros;
    }
    _definir(_edicao.copyWith(itens: itens));
    return const [];
  }

  List<ErroValidacao> _alterarPecas(
    int indiceItem,
    List<PecaOrcamento> pecas,
    List<ErroValidacao> erros,
  ) => _alterarItens(
    [..._edicao.itens]
      ..[indiceItem] = _edicao.itens[indiceItem].copyWith(pecas: pecas),
    erros,
  );

  /// Troca a sessão, limpa os erros e recalcula o resumo.
  void _definir(OrcamentoEmEdicao edicao, {int? etapa}) {
    final validos = validarOrcamento(
      edicao,
    ).where((e) => _pertence(e, _camposDoResumo)).isEmpty;
    state = state.copyWith(
      edicao: edicao,
      etapaAtual: etapa ?? state.etapaAtual,
      erros: const [],
      resumo: validos
          ? const CalculadoraOrcamento().calcularOrcamento(
              itens: edicao.itens,
              insumos: edicao.insumos,
              impostos: edicao.impostos,
              combustivel: edicao.combustivel,
              outros: edicao.outros,
              desconto: edicao.desconto,
            )
          : null,
    );
  }
}
