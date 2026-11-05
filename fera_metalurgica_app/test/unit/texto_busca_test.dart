import 'package:fera_metalurgica_app/core/utils/texto_busca.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizarParaBusca tira maiúsculas e acentos', () {
    expect(
      normalizarParaBusca('Ácme Indústria São João'),
      'acme industria sao joao',
    );
    expect(normalizarParaBusca('MDF 15 mm'), 'mdf 15 mm');
  });

  test('compararNomes ordena sem diferenciar maiúsculas nem acentos', () {
    final nomes = ['João', 'ácme', 'Bruno', 'Álvaro']..sort(compararNomes);
    expect(nomes, ['ácme', 'Álvaro', 'Bruno', 'João']);
  });
}
