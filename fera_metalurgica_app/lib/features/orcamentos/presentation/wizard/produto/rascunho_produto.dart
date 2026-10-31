import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/validacao_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rascunho_produto.freezed.dart';
part 'rascunho_produto.g.dart';

/// Produto em montagem na etapa 2 (prompt §4): o produto só entra na sessão
/// do orçamento com pelo menos uma peça, então as peças ficam aqui até o
/// operador tocar em "Adicionar produto" (ou "Salvar produto", na edição).
/// Estado de tela, não é persistido.
@freezed
abstract class EstadoRascunhoProduto with _$EstadoRascunhoProduto {
  /// Cria um [EstadoRascunhoProduto].
  const factory EstadoRascunhoProduto({
    /// Produto de partida: um vazio, ou a cópia do produto em edição. Os
    /// campos do produto (descrição, quantidade...) ficam no formulário; as
    /// peças, em [pecas].
    required ItemOrcamento origem,

    /// Se edita um produto que já está no orçamento.
    required bool ehEdicao,

    /// Peças já aceitas (validadas) no rascunho, na ordem exibida.
    @Default(<PecaOrcamento>[]) List<PecaOrcamento> pecas,

    /// Peça carregada no formulário da peça, ou `null` para uma peça nova.
    String? pecaEmEdicaoId,

    /// Muda a cada peça adicionada, salva ou cancelada, para o formulário
    /// da peça recomeçar limpo.
    @Default(0) int versaoFormularioPeca,

    /// Se o operador mexeu em algum campo desde que abriu o rascunho.
    @Default(false) bool alterado,

    /// Se o formulário da peça tem dados ainda não aceitos.
    @Default(false) bool pecaPendente,
  }) = _EstadoRascunhoProduto;

  const EstadoRascunhoProduto._();

  /// Peça carregada no formulário da peça, se houver.
  PecaOrcamento? get pecaEmEdicao =>
      pecas.where((p) => p.id == pecaEmEdicaoId).firstOrNull;
}

/// Rascunho do produto da etapa 2; `null` quando nenhum formulário de
/// produto está aberto.
///
/// Só a interface da etapa 2 usa: grava no orçamento pelo
/// `OrcamentoController`, que continua sendo o único dono da sessão.
@riverpod
class RascunhoProduto extends _$RascunhoProduto {
  @override
  EstadoRascunhoProduto? build() => null;

  EstadoRascunhoProduto get _atual {
    final atual = state;
    if (atual == null) throw StateError('Nenhum produto em montagem');
    return atual;
  }

  /// Abre o formulário de um produto novo, com 1 unidade e preço base zero.
  void abrirNovo() => state = EstadoRascunhoProduto(
    origem: ItemOrcamento(
      id: gerarId(),
      descricao: '',
      quantidadeProdutos: 1,
      precoBase: Dinheiro.zero,
      pecas: const [],
    ),
    ehEdicao: false,
  );

  /// Abre o formulário com uma cópia de [item], que já está no orçamento.
  /// Nada muda no orçamento até [concluir].
  void abrirEdicao(ItemOrcamento item) => state = EstadoRascunhoProduto(
    origem: item,
    ehEdicao: true,
    pecas: item.pecas,
  );

  /// Registra que o operador mexeu em algum campo; com [naPeca], num
  /// campo do formulário da peça.
  void marcarAlterado({bool naPeca = false}) {
    final atual = state;
    if (atual == null) return;
    if (!atual.alterado || (naPeca && !atual.pecaPendente)) {
      state = atual.copyWith(
        alterado: true,
        pecaPendente: atual.pecaPendente || naPeca,
      );
    }
  }

  /// Carrega a peça [pecaId] no formulário da peça.
  void editarPeca(String pecaId) => state = _atual.copyWith(
    pecaEmEdicaoId: pecaId,
    versaoFormularioPeca: _atual.versaoFormularioPeca + 1,
    pecaPendente: false,
  );

  /// Limpa o formulário da peça, sem mudar as peças aceitas.
  void limparFormularioPeca() => state = _atual.copyWith(
    pecaEmEdicaoId: null,
    versaoFormularioPeca: _atual.versaoFormularioPeca + 1,
    pecaPendente: false,
  );

  /// Aceita [peca] no rascunho, se for válida: substitui a peça de mesmo id
  /// ou entra no fim. Devolve os erros (vazia = aceita) e, se aceitar,
  /// limpa o formulário da peça.
  List<ErroValidacao> salvarPeca(PecaOrcamento peca) {
    final erros = validarPeca(peca);
    if (erros.isNotEmpty) return erros;
    final pecas = _atual.pecas;
    final indice = pecas.indexWhere((p) => p.id == peca.id);
    state = _atual.copyWith(
      pecas: indice < 0 ? [...pecas, peca] : ([...pecas]..[indice] = peca),
      pecaEmEdicaoId: null,
      versaoFormularioPeca: _atual.versaoFormularioPeca + 1,
      alterado: true,
      pecaPendente: false,
    );
    return const [];
  }

  /// Duplica a peça [pecaId] logo depois dela, com id novo.
  void duplicarPeca(String pecaId) {
    final pecas = _atual.pecas;
    final indice = pecas.indexWhere((p) => p.id == pecaId);
    if (indice < 0) return;
    state = _atual.copyWith(
      pecas: [...pecas]..insert(indice + 1, pecas[indice].duplicar(gerarId())),
      alterado: true,
    );
  }

  /// Tira a peça [pecaId] do rascunho. Se ela estava no formulário, ele
  /// recomeça limpo.
  void removerPeca(String pecaId) {
    final atual = _atual;
    final estavaNoFormulario = atual.pecaEmEdicaoId == pecaId;
    state = atual.copyWith(
      pecas: [
        for (final peca in atual.pecas)
          if (peca.id != pecaId) peca,
      ],
      pecaEmEdicaoId: estavaNoFormulario ? null : atual.pecaEmEdicaoId,
      versaoFormularioPeca:
          atual.versaoFormularioPeca + (estavaNoFormulario ? 1 : 0),
      alterado: true,
      pecaPendente: atual.pecaPendente && !estavaNoFormulario,
    );
  }

  /// Grava o produto montado no orçamento: adiciona, ou substitui o produto
  /// em edição, com os campos do formulário e as peças do rascunho. Devolve
  /// os erros (vazia = gravado) e, se gravar, fecha o rascunho.
  List<ErroValidacao> concluir({
    required String descricao,
    required int quantidadeProdutos,
    required Dinheiro precoBase,
    String? observacoes,
  }) {
    final atual = _atual;
    final item = atual.origem.copyWith(
      descricao: descricao,
      quantidadeProdutos: quantidadeProdutos,
      precoBase: precoBase,
      observacoes: observacoes,
      pecas: atual.pecas,
    );
    final erros = validarItem(item);
    if (erros.isNotEmpty) return erros;
    final controller = ref.read(orcamentoControllerProvider.notifier);
    final errosSessao = atual.ehEdicao
        ? controller.editarItem(item)
        : controller.adicionarItem(item);
    if (errosSessao.isEmpty) state = null;
    return errosSessao;
  }

  /// Fecha o rascunho sem gravar. A interface pede a confirmação antes.
  void descartar() => state = null;
}
