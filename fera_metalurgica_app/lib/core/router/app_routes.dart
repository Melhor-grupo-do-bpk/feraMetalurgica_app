import 'package:flutter/widgets.dart';

/// Navigator raiz. Telas "cheias" (sem a navegação inferior) usam
/// `parentNavigatorKey: rootNavigatorKey` nas suas rotas (D-11).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Mapa de rotas do app (D-11). Navegue sempre pelos helpers daqui, nunca
/// por strings soltas, e nunca use `Navigator.push` direto nas features.
///
/// Os segmentos (`novo`, `:id`, `editar`...) são declarados nos
/// `<feature>_routes.dart`; `test/widget/app_router_test.dart` garante que
/// os helpers e as rotas continuam batendo.
abstract final class AppRoutes {
  /// Aba "Início" (dashboard).
  static const String dashboard = '/';

  /// Aba "Orçamentos" (lista).
  static const String orcamentos = '/orcamentos';

  /// Aba "Catálogo".
  static const String catalogo = '/catalogo';

  /// Aba "Mais" (menu).
  static const String mais = '/mais';

  /// Cronograma, aberto pelo menu da aba "Mais".
  static const String cronograma = '/mais/cronograma';

  /// Wizard de novo orçamento; com [produtoId], já começa com esse produto
  /// do catálogo como primeiro item.
  static String novoOrcamento({String? produtoId}) => Uri(
    path: '$orcamentos/novo',
    queryParameters: produtoId == null ? null : {'produtoId': produtoId},
  ).toString();

  /// Detalhes do orçamento [id].
  static String detalhesOrcamento(String id) => '$orcamentos/$id';

  /// Wizard de edição do orçamento [id].
  static String editarOrcamento(String id) => '$orcamentos/$id/editar';

  /// Prévia do PDF do orçamento [id].
  static String pdfOrcamento(String id) => '$orcamentos/$id/pdf';

  /// Formulário de tarefa: nova, ou edição da tarefa [id].
  static String tarefa({String? id}) => Uri(
    path: '$cronograma/tarefa',
    queryParameters: id == null ? null : {'id': id},
  ).toString();
}
