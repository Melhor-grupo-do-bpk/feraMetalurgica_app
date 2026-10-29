/// API pública da feature `catalogo`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/catalogo_repository_impl.dart';
export 'data/catalogo_seed.dart';
export 'domain/catalogo_repository.dart';
export 'domain/produto_catalogo.dart';
export 'presentation/catalogo_controller.dart';
export 'presentation/catalogo_page.dart';
export 'presentation/catalogo_routes.dart';
