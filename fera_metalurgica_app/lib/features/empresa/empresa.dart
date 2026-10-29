/// API pública da feature `empresa`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/sqlite_empresa_repository.dart';
export 'domain/empresa.dart';
export 'domain/empresa_repository.dart';
export 'domain/validacao_empresa.dart';
