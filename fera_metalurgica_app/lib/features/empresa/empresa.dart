/// API pública da feature `empresa`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/empresa_seed.dart';
export 'data/sqlite_empresa_repository.dart';
export 'domain/empresa.dart';
export 'domain/empresa_repository.dart';
export 'domain/validacao_empresa.dart';
export 'presentation/empresa_controller.dart';
export 'presentation/empresa_page.dart';
export 'presentation/empresa_routes.dart';
