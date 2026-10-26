import 'package:fera_metalurgica_app/features/orcamentos/data/orcamento_repository_impl.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orcamentos_controller.g.dart';

/// Orçamentos salvos, do mais recente ao mais antigo.
///
/// Estado compartilhado da feature: toda tela (inclusive o dashboard) lê
/// daqui e grava pelos métodos abaixo, que atualizam quem estiver ouvindo.
/// Trilhas podem adicionar métodos, mas não renomear/remover os existentes
/// (`docs/03-padroes.md` §2).
@Riverpod(keepAlive: true)
class Orcamentos extends _$Orcamentos {
  @override
  Future<List<Orcamento>> build() async =>
      _ordenar(await ref.watch(orcamentoRepositoryProvider).getAll());

  /// Cria ou atualiza [orcamento].
  Future<void> salvar(Orcamento orcamento) async {
    final repository = ref.read(orcamentoRepositoryProvider);
    await repository.save(orcamento);
    state = AsyncData(_ordenar(await repository.getAll()));
  }

  /// Remove o orçamento de identificador [id].
  Future<void> excluir(String id) async {
    final repository = ref.read(orcamentoRepositoryProvider);
    await repository.delete(id);
    state = AsyncData(_ordenar(await repository.getAll()));
  }

  static List<Orcamento> _ordenar(List<Orcamento> orcamentos) =>
      [...orcamentos]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
}

/// Orçamento de identificador [id], ou `null` se não existir.
@riverpod
Future<Orcamento?> orcamentoPorId(Ref ref, String id) async {
  final orcamentos = await ref.watch(orcamentosProvider.future);
  return orcamentos.where((o) => o.id == id).firstOrNull;
}
