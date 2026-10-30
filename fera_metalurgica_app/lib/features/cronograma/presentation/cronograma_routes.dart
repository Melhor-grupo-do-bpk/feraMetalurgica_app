import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_page.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefa_form/tarefa_form_page.dart';
import 'package:go_router/go_router.dart';

/// Rotas da aba "Agenda" (o cronograma, D-31) e do formulário de tarefa
/// (D-11, D-12).
final GoRoute cronogramaRoute = GoRoute(
  path: AppRoutes.agenda,
  builder: (context, state) => const CronogramaPage(),
  routes: [
    GoRoute(
      path: 'tarefa',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => TarefaFormPage(
        tarefaId: state.uri.queryParameters['id'],
        orcamentoId: state.uri.queryParameters['orcamentoId'],
      ),
    ),
  ],
);
