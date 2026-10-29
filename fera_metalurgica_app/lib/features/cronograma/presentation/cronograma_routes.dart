import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_page.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefa_form/tarefa_form_page.dart';
import 'package:go_router/go_router.dart';

/// Rotas do cronograma, filhas da aba "Mais" (D-11, D-12); por isso o
/// caminho é relativo (`/mais` + `cronograma`). Congelado após a F1.
final GoRoute cronogramaRoute = GoRoute(
  path: 'cronograma',
  builder: (context, state) => const CronogramaPage(),
  routes: [
    GoRoute(
      path: 'tarefa',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          TarefaFormPage(tarefaId: state.uri.queryParameters['id']),
    ),
  ],
);
