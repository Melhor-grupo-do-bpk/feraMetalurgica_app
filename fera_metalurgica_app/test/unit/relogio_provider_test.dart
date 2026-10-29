import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agoraProvider devolve o instante atual', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final antes = DateTime.now();
    final agora = container.read(agoraProvider);

    expect(agora.isBefore(antes), isFalse);
    expect(agora.difference(antes).inSeconds, lessThan(5));
  });

  test('agoraProvider pode ser fixado nos testes', () {
    final fixo = DateTime(2023, 10, 9, 8);
    final container = ProviderContainer(
      overrides: [agoraProvider.overrideWithValue(fixo)],
    );
    addTearDown(container.dispose);

    expect(container.read(agoraProvider), fixo);
  });
}
