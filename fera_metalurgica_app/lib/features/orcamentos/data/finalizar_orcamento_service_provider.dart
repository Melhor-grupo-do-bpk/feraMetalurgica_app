import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_unidade_de_trabalho.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/finalizar_orcamento_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'finalizar_orcamento_service_provider.g.dart';

/// [FinalizarOrcamentoService] do app: transação do SQLite, o "agora" do
/// `agoraProvider` (lido no momento de gravar) e ids UUID.
@riverpod
FinalizarOrcamentoService finalizarOrcamentoService(Ref ref) {
  final unidadeDeTrabalho = ref.watch(unidadeDeTrabalhoProvider);
  return FinalizarOrcamentoService(
    unidadeDeTrabalho: unidadeDeTrabalho,
    relogio: () => ref.read(agoraProvider),
    gerarId: gerarId,
  );
}
