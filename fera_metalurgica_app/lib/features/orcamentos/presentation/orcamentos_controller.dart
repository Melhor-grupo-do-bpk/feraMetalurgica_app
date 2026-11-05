import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orcamentos_controller.g.dart';

/// Orçamentos salvos, com os totais gravados, do `atualizadoEm` mais
/// recente para o mais antigo.
///
/// Estado compartilhado da feature: toda tela (inclusive o dashboard) lê
/// daqui. Criar e editar passam pelo `OrcamentoController` (que recarrega
/// esta lista ao salvar); excluir e mudar o status, pelos métodos abaixo.
/// Trilhas podem adicionar métodos, mas não renomear/remover os existentes
/// (`docs/03-padroes.md` §2).
@Riverpod(keepAlive: true)
class Orcamentos extends _$Orcamentos {
  @override
  Future<List<Orcamento>> build() =>
      ref.watch(orcamentoRepositoryProvider).listarResumos();

  /// Exclui o orçamento [id] com seus itens e peças. O código não volta a
  /// ser usado (D-30).
  Future<void> excluir(String id) async {
    await ref.read(orcamentoRepositoryProvider).excluir(id);
    await recarregar();
  }

  /// Muda o status do orçamento [id] (D-29), sem mexer no `atualizadoEm`
  /// nem na revisão. Passar para `enviado` grava o `enviadoEm` com o
  /// "agora"; voltar para `criado` o limpa (D-37). Não faz nada se o
  /// orçamento não existir ou já estiver nesse status.
  Future<void> alterarStatus(String id, StatusOrcamento status) async {
    final repository = ref.read(orcamentoRepositoryProvider);
    final orcamento = await repository.buscarPorId(id);
    if (orcamento == null || orcamento.status == status) return;
    await repository.atualizar(
      orcamento.copyWith(
        status: status,
        enviadoEm: status == StatusOrcamento.enviado
            ? ref.read(agoraProvider)
            : null,
      ),
    );
    await recarregar();
  }

  /// Lê de novo a lista do banco (ex: depois de salvar pelo wizard).
  Future<void> recarregar() async => state = AsyncData(
    await ref.read(orcamentoRepositoryProvider).listarResumos(),
  );
}

/// Orçamento de identificador [id], ou `null` se não existir.
@riverpod
Future<Orcamento?> orcamentoPorId(Ref ref, String id) async {
  final orcamentos = await ref.watch(orcamentosProvider.future);
  return orcamentos.where((o) => o.id == id).firstOrNull;
}
