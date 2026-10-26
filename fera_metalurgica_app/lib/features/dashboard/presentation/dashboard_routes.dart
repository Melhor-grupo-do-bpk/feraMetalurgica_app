import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/dashboard_page.dart';
import 'package:go_router/go_router.dart';

/// Rota da aba "Início" (D-11, D-12). Congelado após a F1.
final GoRoute dashboardRoute = GoRoute(
  path: AppRoutes.dashboard,
  builder: (context, state) => const DashboardPage(),
);
