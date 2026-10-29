/// API pública da feature `cronograma`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/cronograma_seed.dart';
export 'data/sqlite_tarefa_repository.dart';
export 'domain/tarefa.dart';
export 'domain/tarefa_repository.dart';
export 'domain/tipo_tarefa.dart';
export 'presentation/cronograma_controller.dart';
export 'presentation/cronograma_page.dart';
export 'presentation/cronograma_routes.dart';
export 'presentation/cronograma_ui.dart';
export 'presentation/tarefa_form/tarefa_form_page.dart';
