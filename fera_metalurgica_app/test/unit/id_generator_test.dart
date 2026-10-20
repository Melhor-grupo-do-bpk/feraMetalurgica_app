import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gerarId devolve UUIDs v4 distintos', () {
    final ids = List.generate(100, (_) => gerarId());

    expect(ids.toSet(), hasLength(100));
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });
}
