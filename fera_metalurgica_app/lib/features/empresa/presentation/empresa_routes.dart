import 'package:fera_metalurgica_app/features/empresa/presentation/empresa_page.dart';
import 'package:go_router/go_router.dart';

/// Rota dos dados da empresa, filha da aba "Mais" (D-31); por isso o
/// caminho é relativo (`/mais` + `empresa`).
final GoRoute empresaRoute = GoRoute(
  path: 'empresa',
  builder: (context, state) => const EmpresaPage(),
);
