import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculo_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/custos_operacionais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orcamento_wizard_controller.g.dart';

/// Quantidade de etapas do wizard.
const int totalEtapasWizard = 4;

/// Estado do wizard de orçamento (D-21).
///
/// Com [orcamentoId], edita o orçamento salvo; com [produtoId], começa um
/// orçamento novo cujo 1º item é esse produto do catálogo (RF-27). O estado
/// é `null` quando o orçamento em edição não existe. Um [produtoId] que não
/// existe no catálogo é ignorado.
@riverpod
class OrcamentoWizardController extends _$OrcamentoWizardController {
  @override
  Future<OrcamentoWizardState?> build({
    String? orcamentoId,
    String? produtoId,
  }) async {
    // `read` (e não `watch`): o wizard carrega uma vez. Se observasse os
    // orçamentos, o próprio `concluir()` reiniciaria o estado.
    if (orcamentoId != null) {
      final orcamentos = await ref.read(orcamentosProvider.future);
      final orcamento = orcamentos.where((o) => o.id == orcamentoId);
      if (orcamento.isEmpty) return null;
      return OrcamentoWizardState(
        orcamento: orcamento.first,
        inicial: orcamento.first,
        edicao: true,
      );
    }

    final produtos = produtoId == null
        ? const <ProdutoCatalogo>[]
        : await ref.read(produtosCatalogoProvider.future);
    final produto = produtos.where((p) => p.id == produtoId).firstOrNull;
    final novo = Orcamento(
      id: '',
      cliente: Cliente(id: gerarId(), nome: '', numero: '', cpfCnpj: ''),
      projeto: '',
      itens: [
        if (produto != null)
          ItemOrcamento(
            id: gerarId(),
            tipoServico: produto.nome,
            produtoId: produto.id,
          ),
      ],
      custosOperacionais: const CustosOperacionais(),
      status: StatusOrcamento.emAnalise,
      criadoEm: ref.read(agoraProvider),
    );
    return OrcamentoWizardState(orcamento: novo, inicial: novo, edicao: false);
  }

  OrcamentoWizardState get _atual => state.requireValue!;

  void _alterar(Orcamento Function(Orcamento) alteracao) {
    final atual = _atual;
    state = AsyncData(atual.copyWith(orcamento: alteracao(atual.orcamento)));
  }

  /// Troca os dados do cliente (etapa 1). Textos são aparados, e e-mail e
  /// observações vazios viram `null`.
  void atualizarCliente({
    required String nome,
    required String numero,
    required String cpfCnpj,
    String? email,
    String? observacoes,
  }) => _alterar(
    (o) => o.copyWith(
      cliente: o.cliente.copyWith(
        nome: nome.trim(),
        numero: numero.trim(),
        cpfCnpj: cpfCnpj.trim(),
        email: _textoOuNull(email),
        observacoes: _textoOuNull(observacoes),
      ),
    ),
  );

  /// Troca o nome do projeto (etapa 2, D-02).
  void atualizarProjeto(String projeto) =>
      _alterar((o) => o.copyWith(projeto: projeto.trim()));

  /// Acrescenta [item] ao fim da lista (etapa 2).
  void adicionarItem(ItemOrcamento item) =>
      _alterar((o) => o.copyWith(itens: [...o.itens, item]));

  /// Substitui o item de mesmo `id` que [item], mantendo a posição.
  void atualizarItem(ItemOrcamento item) => _alterar(
    (o) => o.copyWith(
      itens: [
        for (final i in o.itens)
          if (i.id == item.id) item else i,
      ],
    ),
  );

  /// Remove o item de identificador [id].
  void removerItem(String id) => _alterar(
    (o) => o.copyWith(itens: o.itens.where((i) => i.id != id).toList()),
  );

  /// Troca os custos operacionais (etapa 3).
  void atualizarCustos(CustosOperacionais custos) =>
      _alterar((o) => o.copyWith(custosOperacionais: custos));

  /// Se a [etapa] (1 a 4) tem o que precisa para seguir: cliente válido na
  /// 1 (RF-21) e pelo menos um item na 2 (RF-22). A 3 aceita qualquer
  /// valor, inclusive total zero (ver HO-T3-01).
  bool etapaValida(int etapa) {
    final orcamento = _atual.orcamento;
    return switch (etapa) {
      1 => _clienteValido(orcamento.cliente),
      2 => orcamento.itens.isNotEmpty,
      _ => true,
    };
  }

  /// Vai para a próxima etapa se a atual for válida. Retorna se avançou.
  bool avancar() {
    final etapa = _atual.etapa;
    if (etapa >= totalEtapasWizard || !etapaValida(etapa)) return false;
    state = AsyncData(_atual.copyWith(etapa: etapa + 1));
    return true;
  }

  /// Volta uma etapa, mantendo o que foi digitado. Retorna `false` na
  /// etapa 1, quando quem chamou deve sair do wizard.
  bool voltar() {
    final etapa = _atual.etapa;
    if (etapa <= 1) return false;
    state = AsyncData(_atual.copyWith(etapa: etapa - 1));
    return true;
  }

  /// Grava o orçamento e retorna o id dele.
  ///
  /// Um orçamento novo recebe o próximo número (D-09), a data atual e o
  /// status `emAnalise` (RF-25); na edição, `id`, `criadoEm` e `status` são
  /// mantidos (RF-26). Sem nome de projeto, usa o tipo do 1º item (D-02).
  Future<String> concluir() async {
    final atual = _atual;
    if (!etapaValida(1) || !etapaValida(2)) {
      throw StateError('Orçamento incompleto: cliente inválido ou sem itens.');
    }
    var orcamento = atual.orcamento;
    if (orcamento.projeto.isEmpty) {
      orcamento = orcamento.copyWith(
        projeto: orcamento.itens.first.tipoServico,
      );
    }
    if (!atual.edicao) {
      final existentes = await ref.read(orcamentosProvider.future);
      orcamento = orcamento.copyWith(
        id: proximoIdOrcamento(existentes),
        criadoEm: ref.read(agoraProvider),
        status: StatusOrcamento.emAnalise,
      );
    }
    await ref.read(orcamentosProvider.notifier).salvar(orcamento);
    return orcamento.id;
  }

  static bool _clienteValido(Cliente cliente) =>
      validarObrigatorio(cliente.nome) == null &&
      validarTelefone(cliente.numero) == null &&
      validarCpfCnpj(cliente.cpfCnpj) == null &&
      validarEmail(cliente.email) == null;

  static String? _textoOuNull(String? texto) {
    final aparado = texto?.trim() ?? '';
    return aparado.isEmpty ? null : aparado;
  }
}
