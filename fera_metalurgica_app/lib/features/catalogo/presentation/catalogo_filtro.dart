import 'package:fera_metalurgica_app/features/catalogo/domain/produto_catalogo.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/catalogo_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalogo_filtro.g.dart';

/// Chips e produtos visíveis da Tela 9. `selecionada == null` é o chip
/// "Todos".
typedef CatalogoFiltrado = ({
  List<String> categorias,
  String? selecionada,
  List<ProdutoCatalogo> produtos,
});

/// Categoria escolhida nos chips do catálogo; `null` é "Todos". Não é
/// persistida.
@riverpod
class CatalogoCategoria extends _$CatalogoCategoria {
  @override
  String? build() => null;

  /// Categoria selecionada; `null` é "Todos".
  String? get categoria => state;

  /// Troca o chip selecionado; `null` volta para "Todos".
  set categoria(String? categoria) => state = categoria;
}

/// Produtos de [produtosCatalogoProvider] filtrados pela categoria
/// selecionada, mais as categorias dos chips.
///
/// Se a categoria selecionada deixar de existir no catálogo, o filtro volta
/// para "Todos", para a tela não ficar vazia com um chip que sumiu.
@riverpod
AsyncValue<CatalogoFiltrado> catalogoFiltrado(Ref ref) {
  final categoria = ref.watch(catalogoCategoriaProvider);
  return ref.watch(produtosCatalogoProvider).whenData((produtos) {
    final categorias = categoriasDoCatalogo(produtos);
    final selecionada = categorias.contains(categoria) ? categoria : null;
    return (
      categorias: categorias,
      selecionada: selecionada,
      produtos: filtrarPorCategoria(produtos, selecionada),
    );
  });
}

/// Categorias distintas de [produtos], em ordem alfabética (D-18).
List<String> categoriasDoCatalogo(List<ProdutoCatalogo> produtos) =>
    {for (final p in produtos) p.categoria}.toList()..sort();

/// Produtos de [categoria], mantendo a ordem; `null` devolve todos.
List<ProdutoCatalogo> filtrarPorCategoria(
  List<ProdutoCatalogo> produtos,
  String? categoria,
) => [
  for (final p in produtos)
    if (categoria == null || p.categoria == categoria) p,
];
