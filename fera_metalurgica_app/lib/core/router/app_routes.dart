import 'package:flutter/widgets.dart';

/// Navigator raiz. Telas "cheias" (sem a navegação inferior) usam
/// `parentNavigatorKey: rootNavigatorKey` nas suas rotas (D-11).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Mapa de rotas do app (D-11, D-31). Navegue sempre pelos helpers daqui,
/// nunca por strings soltas, e nunca use `Navigator.push` direto nas
/// features.
///
/// Os segmentos (`novo`, `:id`, `editar`...) são declarados nos
/// `<feature>_routes.dart`; `test/widget/app_router_test.dart` garante que
/// os helpers e as rotas continuam batendo.
abstract final class AppRoutes {
  /// Aba "Início" (dashboard).
  static const String dashboard = '/';

  /// Aba "Orçamentos" (lista).
  static const String orcamentos = '/orcamentos';

  /// Aba "Agenda" (o cronograma, D-31).
  static const String agenda = '/agenda';

  /// Aba "Mais" (menu).
  static const String mais = '/mais';

  /// Cadastro de materiais (lista), aberto pelo menu da aba "Mais".
  static const String materiais = '$mais/materiais';

  /// Dados da empresa emitente, abertos pelo menu da aba "Mais". Sem a
  /// empresa completa, "Novo orçamento" e "Editar" redirecionam para cá
  /// (prompt §3.2).
  static const String empresa = '$mais/empresa';

  /// Wizard de novo orçamento.
  static String novoOrcamento() => '$orcamentos/novo';

  /// Detalhes do orçamento [id].
  static String detalhesOrcamento(String id) => '$orcamentos/$id';

  /// Wizard de edição do orçamento [id] (D-30).
  static String editarOrcamento(String id) => '$orcamentos/$id/editar';

  /// Prévia do PDF do orçamento [id].
  static String pdfOrcamento(String id) => '$orcamentos/$id/pdf';

  /// Formulário de material: novo, ou edição do material [id].
  ///
  /// Contrato do atalho "Cadastrar material":
  /// `context.push<String>(AppRoutes.material())` devolve o id do material
  /// salvo (ou `null` se o operador voltar sem salvar).
  static String material({String? id}) => Uri(
    path: '$materiais/material',
    queryParameters: id == null ? null : {'id': id},
  ).toString();

  /// Formulário de tarefa: nova, ou edição da tarefa [id]. Com
  /// [orcamentoId], a tarefa nova já vem vinculada a esse orçamento
  /// ("Agendar" nos detalhes).
  static String tarefa({String? id, String? orcamentoId}) {
    final parametros = {'id': ?id, 'orcamentoId': ?orcamentoId};
    return Uri(
      path: '$agenda/tarefa',
      queryParameters: parametros.isEmpty ? null : parametros,
    ).toString();
  }
}
