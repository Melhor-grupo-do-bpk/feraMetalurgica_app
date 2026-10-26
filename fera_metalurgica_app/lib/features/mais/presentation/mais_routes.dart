import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/mais/presentation/mais_page.dart';
import 'package:go_router/go_router.dart';

/// Rota da aba "Mais" e das telas abertas pelo menu (D-11, D-12, D-13).
final GoRoute maisRoute = GoRoute(
  path: AppRoutes.mais,
  builder: (context, state) => const MaisPage(),
  routes: [cronogramaRoute],
);
