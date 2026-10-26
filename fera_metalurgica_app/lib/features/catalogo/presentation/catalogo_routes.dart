import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/catalogo_page.dart';
import 'package:go_router/go_router.dart';

/// Rota da aba "Catálogo" (D-11, D-12). Congelado após a F1.
final GoRoute catalogoRoute = GoRoute(
  path: AppRoutes.catalogo,
  builder: (context, state) => const CatalogoPage(),
);
