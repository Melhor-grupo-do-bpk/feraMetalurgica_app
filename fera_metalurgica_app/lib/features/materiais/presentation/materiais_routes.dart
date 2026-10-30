import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/form/material_form_page.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/lista/materiais_page.dart';
import 'package:go_router/go_router.dart';

/// Rotas do cadastro de materiais, filhas da aba "Mais" (D-31); por isso o
/// caminho é relativo (`/mais` + `materiais`). O formulário abre em tela
/// cheia.
final GoRoute materiaisRoute = GoRoute(
  path: 'materiais',
  builder: (context, state) => const MateriaisPage(),
  routes: [
    GoRoute(
      path: 'material',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          MaterialFormPage(materialId: state.uri.queryParameters['id']),
    ),
  ],
);
