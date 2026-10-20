import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_catalogo_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    final repository = MockCatalogoRepository();
    when(repository.getAll).thenAnswer((_) async => catalogoSeed);
    container = ProviderContainer(
      overrides: [catalogoRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('carrega os produtos do repositório', () async {
    expect(await container.read(produtosCatalogoProvider.future), catalogoSeed);
  });

  test('produtoPorId encontra o produto ou devolve null', () async {
    expect(
      await container.read(
        produtoPorIdProvider('produto-portao-basculante').future,
      ),
      catalogoSeed.first,
    );
    expect(
      await container.read(produtoPorIdProvider('inexistente').future),
      isNull,
    );
  });
}
