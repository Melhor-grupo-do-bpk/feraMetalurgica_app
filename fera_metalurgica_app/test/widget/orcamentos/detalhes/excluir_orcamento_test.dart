import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/container_de_teste.dart';

/// Excluir pelos detalhes (D-30), num arquivo sem outro banco aberto: com
/// dois bancos em memória abertos ao mesmo tempo, os dados se misturam.
void main() {
  test('excluir não libera o código do dia (D-30)', () async {
    final container = await containerDeTeste(agora: DateTime(2026, 10, 30, 12));
    // Os exemplos de debug: B ontem e C anteontem, o 1º do dia (D-38).
    final [_, c] = await container.read(orcamentosProvider.future);
    expect(c.codigo, '281026-01');

    await container.read(orcamentosProvider.notifier).excluir(c.id);

    expect(await container.read(orcamentosProvider.future), hasLength(1));
    final proxima = await SqliteSequenciaRepository(
      container.read(bancoDeDadosProvider),
    ).proximaDoDia(c.criadoEm);
    expect(formatarCodigoOrcamento(c.criadoEm, proxima), '281026-02');
  });
}
