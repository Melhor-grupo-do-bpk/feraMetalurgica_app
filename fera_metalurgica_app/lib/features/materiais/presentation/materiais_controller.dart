import 'package:fera_metalurgica_app/features/materiais/data/sqlite_material_repository.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'materiais_controller.g.dart';

/// Todos os materiais, ativos e inativos, ordenados por nome (tela de
/// cadastro).
///
/// Estado compartilhado da feature: grave pelos métodos abaixo, que
/// atualizam quem estiver ouvindo (inclusive [materiaisAtivosProvider]).
/// Trilhas podem adicionar métodos, mas não renomear/remover os existentes
/// (`docs/03-padroes.md` §2).
@Riverpod(keepAlive: true)
class Materiais extends _$Materiais {
  @override
  Future<List<Material>> build() =>
      ref.watch(materialRepositoryProvider).listarTodos();

  /// Cria ou atualiza [material].
  Future<void> salvar(Material material) async {
    await ref.read(materialRepositoryProvider).salvar(material);
    await _recarregar();
  }

  /// Inativa o material [id]: some das novas seleções.
  Future<void> inativar(String id) async {
    await ref.read(materialRepositoryProvider).inativar(id);
    await _recarregar();
  }

  /// Reativa o material [id].
  Future<void> reativar(String id) async {
    await ref.read(materialRepositoryProvider).reativar(id);
    await _recarregar();
  }

  Future<void> _recarregar() async => state = AsyncData(
    await ref.read(materialRepositoryProvider).listarTodos(),
  );
}

/// Material de identificador [id], ou `null` se não existir.
@riverpod
Future<Material?> materialPorId(Ref ref, String id) async {
  final materiais = await ref.watch(materiaisProvider.future);
  return materiais.where((m) => m.id == id).firstOrNull;
}

/// Só os materiais ativos, para novas seleções na peça (prompt §3.1).
///
/// Síncrono de propósito, como os filtros das listas: gravar um material
/// não volta a tela para o estado de carregamento.
@riverpod
AsyncValue<List<Material>> materiaisAtivos(Ref ref) => ref
    .watch(materiaisProvider)
    .whenData(
      (materiais) => [
        for (final m in materiais)
          if (m.ativo) m,
      ],
    );
