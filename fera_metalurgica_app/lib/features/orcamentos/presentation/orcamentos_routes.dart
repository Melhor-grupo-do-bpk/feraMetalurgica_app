import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/detalhes/orcamento_detalhes_page.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamentos_lista_page.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/pdf/orcamento_pdf_page.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_page.dart';
import 'package:go_router/go_router.dart';

/// Rotas da feature: a aba "Orçamentos" e as telas cheias abertas a partir
/// dela (D-11, D-12). Congelado após a F1: as trilhas implementam as
/// páginas, não mexem aqui.
final GoRoute orcamentosRoute = GoRoute(
  path: AppRoutes.orcamentos,
  builder: (context, state) => const OrcamentosListaPage(),
  routes: [
    // `novo` antes de `:id`; senão "novo" seria lido como um id.
    GoRoute(
      path: 'novo',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => OrcamentoWizardPage(
        produtoId: state.uri.queryParameters['produtoId'],
      ),
    ),
    GoRoute(
      path: ':id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          OrcamentoDetalhesPage(orcamentoId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'editar',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              OrcamentoWizardPage(orcamentoId: state.pathParameters['id']),
        ),
        GoRoute(
          path: 'pdf',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              OrcamentoPdfPage(orcamentoId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
