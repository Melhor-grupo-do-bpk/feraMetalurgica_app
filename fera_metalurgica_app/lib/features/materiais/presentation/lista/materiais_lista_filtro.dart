import 'package:fera_metalurgica_app/core/utils/texto_busca.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'materiais_lista_filtro.g.dart';

/// Chips de situação da lista de materiais, na ordem de exibição.
enum SituacaoMaterialFiltro {
  /// Só os materiais ativos.
  ativos('Ativos'),

  /// Só os materiais inativos.
  inativos('Inativos'),

  /// Ativos e inativos.
  todos('Todos');

  const SituacaoMaterialFiltro(this.label);

  /// Texto do chip.
  final String label;

  /// Se [material] aparece com este chip selecionado.
  bool aceita(Material material) => switch (this) {
    SituacaoMaterialFiltro.ativos => material.ativo,
    SituacaoMaterialFiltro.inativos => !material.ativo,
    SituacaoMaterialFiltro.todos => true,
  };
}

/// Busca e chip de situação da lista de materiais; não é persistido.
typedef FiltroMateriais = ({String busca, SituacaoMaterialFiltro situacao});

/// Estado da busca e do filtro da lista de materiais. Começa em "Ativos".
@riverpod
class MateriaisListaFiltro extends _$MateriaisListaFiltro {
  @override
  FiltroMateriais build() =>
      (busca: '', situacao: SituacaoMaterialFiltro.ativos);

  /// Troca o texto da busca.
  void buscar(String busca) => state = (busca: busca, situacao: state.situacao);

  /// Troca o chip de situação.
  void filtrarPorSituacao(SituacaoMaterialFiltro situacao) =>
      state = (busca: state.busca, situacao: situacao);
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
      if (filtro.situacao.aceita(m) &&
          (busca.isEmpty || normalizarParaBusca(m.nome).contains(busca)))
        m,
  ];
}
