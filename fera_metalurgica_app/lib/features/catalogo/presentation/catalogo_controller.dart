import 'package:fera_metalurgica_app/features/catalogo/data/catalogo_repository_impl.dart';
import 'package:fera_metalurgica_app/features/catalogo/domain/produto_catalogo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalogo_controller.g.dart';

/// Produtos do catálogo, na ordem em que foram cadastrados.
///
/// Estado compartilhado da feature (lido também pelo wizard de orçamento).
/// Trilhas podem adicionar métodos, mas não renomear/remover os existentes
/// (`docs/03-padroes.md` §2).
@Riverpod(keepAlive: true)
class ProdutosCatalogo extends _$ProdutosCatalogo {
  @override
  Future<List<ProdutoCatalogo>> build() =>
      ref.watch(catalogoRepositoryProvider).getAll();
}

/// Produto de identificador [id], ou `null` se não existir.
@riverpod
Future<ProdutoCatalogo?> produtoPorId(Ref ref, String id) async {
  final produtos = await ref.watch(produtosCatalogoProvider.future);
  return produtos.where((p) => p.id == id).firstOrNull;
}
