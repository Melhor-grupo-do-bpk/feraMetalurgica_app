import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/catalogo_filtro.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_catalogo_repository.dart';

void main() {
  final portao = catalogoSeed[0];
  final trelica = catalogoSeed[1];
  final grade = catalogoSeed[2];

  group('categoriasDoCatalogo', () {
    test('distintas e em ordem alfabética (D-18)', () {
      final outroPortao = portao.copyWith(id: 'outro', nome: 'Outro portão');
      expect(categoriasDoCatalogo([...catalogoSeed, outroPortao]), [
        'Estruturas',
        'Grades',
        'Portões',
      ]);
    });

    test('vazia sem produtos', () {
      expect(categoriasDoCatalogo([]), isEmpty);
    });
  });

  group('filtrarPorCategoria', () {
    test('null devolve todos, na mesma ordem', () {
      expect(filtrarPorCategoria(catalogoSeed, null), catalogoSeed);
    });

    test('mantém só os produtos da categoria', () {
      expect(filtrarPorCategoria(catalogoSeed, 'Grades'), [grade]);
    });
  });

  group('catalogoFiltradoProvider', () {
    late MockCatalogoRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = MockCatalogoRepository();
      when(() => repository.getAll()).thenAnswer((_) async => catalogoSeed);
      container = ProviderContainer(
        overrides: [catalogoRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.listen(catalogoFiltradoProvider, (_, _) {});
    });

    Future<CatalogoFiltrado> filtrado() async {
      await container.read(produtosCatalogoProvider.future);
      return container.read(catalogoFiltradoProvider).requireValue;
    }

    test('começa em "Todos" com todos os produtos', () async {
      final resultado = await filtrado();
      expect(resultado.selecionada, isNull);
      expect(resultado.produtos, catalogoSeed);
      expect(resultado.categorias, ['Estruturas', 'Grades', 'Portões']);
    });

    test('filtra pela categoria selecionada', () async {
      container.read(catalogoCategoriaProvider.notifier).categoria =
          'Estruturas';
      final resultado = await filtrado();
      expect(resultado.selecionada, 'Estruturas');
      expect(resultado.produtos, [trelica]);
    });

    test('categoria que deixou de existir volta para "Todos"', () async {
      container.read(catalogoCategoriaProvider.notifier).categoria = 'Telhas';
      final resultado = await filtrado();
      expect(resultado.selecionada, isNull);
      expect(resultado.produtos, catalogoSeed);
    });
  });
}
