/// API pública da feature `clientes`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/celular_localizacao_repository.dart';
export 'data/sqlite_cliente_repository.dart';
export 'data/via_cep_repository.dart';
export 'domain/cep_repository.dart';
export 'domain/cliente.dart';
export 'domain/cliente_repository.dart';
export 'domain/endereco_encontrado.dart';
export 'domain/localizacao_repository.dart';
export 'domain/validacao_cliente.dart';
export 'presentation/clientes_controller.dart';
