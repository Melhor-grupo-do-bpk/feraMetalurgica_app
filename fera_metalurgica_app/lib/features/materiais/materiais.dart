/// API pública da feature `materiais`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
///
/// Atenção: `Material` tem o mesmo nome do widget do Flutter. Em arquivos
/// que importam `package:flutter/material.dart`, use
/// `import '.../materiais.dart' as materiais;` ou `hide Material` no import
/// do Flutter.
library;

export 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';

export 'domain/material.dart';
export 'domain/material_repository.dart';
export 'domain/validacao_material.dart';
