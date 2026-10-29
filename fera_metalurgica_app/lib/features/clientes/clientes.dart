/// API pública da feature `clientes`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/sqlite_cliente_repository.dart';
export 'domain/cliente.dart';
export 'domain/cliente_repository.dart';
export 'domain/validacao_cliente.dart';
