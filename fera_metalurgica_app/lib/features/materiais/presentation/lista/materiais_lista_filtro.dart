import 'package:fera_metalurgica_app/core/utils/texto_busca.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'materiais_lista_filtro.g.dart';

/// Busca e chip Ativos/Todos da lista de materiais; não é persistido.
typedef FiltroMateriais = ({String busca, bool somenteAtivos});

/// Estado da busca e do filtro da lista de materiais. Começa em "Ativos".
@riverpod
class MateriaisListaFiltro extends _$MateriaisListaFiltro {
  @override
  FiltroMateriais build() => (busca: '', somenteAtivos: true);

  /// Troca o texto da busca.
  void buscar(String busca) =>
      state = (busca: busca, somenteAtivos: state.somenteAtivos);

  /// Troca o chip: `true` é "Ativos", `false` é "Todos".
  void filtrarSomenteAtivos({required bool somenteAtivos}) =>
      state = (busca: state.busca, somenteAtivos: somenteAtivos);
}

/// Materiais de [materiaisProvider] que passam pelo filtro da tela, na
/// mesma ordem (por nome).
///
/// Síncrono de propósito: assim digitar na busca não volta a lista para o
/// estado de carregamento.
@riverpod
AsyncValue<List<Material>> materiaisListaFiltrados(Ref ref) {
  final filtro = ref.watch(materiaisListaFiltroProvider);
  return ref
      .watch(materiaisProvider)
      .whenData((materiais) => filtrarMateriais(materiais, filtro));
}

/// Aplica [filtro] a [materiais], mantendo a ordem. A busca casa com o
/// nome, sem diferenciar maiúsculas nem acentos.
List<Material> filtrarMateriais(
  List<Material> materiais,
  FiltroMateriais filtro,
) {
  final busca = normalizarParaBusca(filtro.busca.trim());
  return [
    for (final m in materiais)
      if ((!filtro.somenteAtivos || m.ativo) &&
          (busca.isEmpty || normalizarParaBusca(m.nome).contains(busca)))
        m,
  ];
}
