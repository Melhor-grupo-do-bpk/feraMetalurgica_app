import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orcamentos_lista_filtro.g.dart';

/// Busca e chip de status da lista de orçamentos (D-22). `status == null`
/// é o chip "Todos".
typedef FiltroOrcamentos = ({String busca, StatusOrcamento? status});

/// Estado da busca e do filtro da Tela 8; não é persistido (D-22).
@riverpod
class OrcamentosListaFiltro extends _$OrcamentosListaFiltro {
  @override
  FiltroOrcamentos build() => (busca: '', status: null);

  /// Troca o texto da busca.
  void buscar(String busca) => state = (busca: busca, status: state.status);

  /// Troca o chip selecionado; `null` volta para "Todos".
  void filtrarPorStatus(StatusOrcamento? status) =>
      state = (busca: state.busca, status: status);
}

/// Orçamentos de [orcamentosProvider] que passam pelo filtro da tela, na
/// mesma ordem (mais recente primeiro).
///
/// Síncrono de propósito: assim digitar na busca não volta a lista para o
/// estado de carregamento.
@riverpod
AsyncValue<List<Orcamento>> orcamentosListaFiltrados(Ref ref) {
  final filtro = ref.watch(orcamentosListaFiltroProvider);
  return ref
      .watch(orcamentosProvider)
      .whenData((orcamentos) => filtrarOrcamentos(orcamentos, filtro));
}

/// Aplica [filtro] a [orcamentos], mantendo a ordem.
///
/// A busca casa com o nome do cliente (sem diferenciar maiúsculas nem
/// acentos) ou, se tiver dígitos, com o número do orçamento comparado só
/// pelos dígitos (ex: "482" e "#00482" encontram o #00482).
List<Orcamento> filtrarOrcamentos(
  List<Orcamento> orcamentos,
  FiltroOrcamentos filtro,
) {
  final busca = _normalizar(filtro.busca.trim());
  final digitos = somenteDigitos(filtro.busca);

  bool casaBusca(Orcamento o) =>
      busca.isEmpty ||
      _normalizar(o.cliente.nome).contains(busca) ||
      (digitos.isNotEmpty && somenteDigitos(o.id).contains(digitos));

  return [
    for (final o in orcamentos)
      if ((filtro.status == null || o.status == filtro.status) && casaBusca(o))
        o,
  ];
}

const String _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const String _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

// TODO(T8): mover para `core/utils/` se outra tela precisar (HO-T2-02).
String _normalizar(String texto) {
  final buffer = StringBuffer();
  for (final char in texto.toLowerCase().split('')) {
    final i = _comAcento.indexOf(char);
    buffer.write(i < 0 ? char : _semAcento[i]);
  }
  return buffer.toString();
}
