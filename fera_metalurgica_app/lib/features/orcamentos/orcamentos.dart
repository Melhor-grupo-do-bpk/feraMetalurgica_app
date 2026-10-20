/// API pública da feature `orcamentos`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/orcamento_repository_impl.dart';
export 'data/orcamentos_seed.dart';
export 'domain/calculo_orcamento.dart';
export 'domain/cliente.dart';
export 'domain/custos_operacionais.dart';
export 'domain/item_orcamento.dart';
export 'domain/medidas.dart';
export 'domain/orcamento.dart';
export 'domain/orcamento_repository.dart';
export 'domain/status_orcamento.dart';
export 'presentation/detalhes/orcamento_detalhes_page.dart';
export 'presentation/lista/orcamentos_lista_page.dart';
export 'presentation/orcamentos_controller.dart';
export 'presentation/orcamentos_routes.dart';
export 'presentation/orcamentos_ui.dart';
export 'presentation/pdf/orcamento_pdf_page.dart';
export 'presentation/wizard/orcamento_wizard_page.dart';
