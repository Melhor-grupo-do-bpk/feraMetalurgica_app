/// API pública da feature `orcamentos`. Outras features/camadas devem
/// importar apenas este arquivo, nunca arquivos internos de
/// `data/`/`domain/`/`presentation/` diretamente.
library;

export 'data/finalizar_orcamento_service_provider.dart';
export 'data/orcamentos_seed.dart';
export 'data/sqlite_orcamento_repository.dart';
export 'data/sqlite_sequencia_repository.dart';
export 'data/sqlite_unidade_de_trabalho.dart';
export 'domain/calculadora_orcamento.dart';
export 'domain/cliente_snapshot.dart';
export 'domain/codigo_orcamento.dart';
export 'domain/empresa_snapshot.dart';
export 'domain/finalizar_orcamento_service.dart';
export 'domain/item_orcamento.dart';
export 'domain/material_snapshot.dart';
export 'domain/orcamento.dart';
export 'domain/orcamento_em_edicao.dart';
export 'domain/orcamento_repository.dart';
export 'domain/peca_orcamento.dart';
export 'domain/resultado_item.dart';
export 'domain/resultado_orcamento.dart';
export 'domain/resultado_peca.dart';
export 'domain/sequencia_repository.dart';
export 'domain/status_orcamento.dart';
export 'domain/unidade_de_trabalho.dart';
export 'domain/validacao_orcamento.dart';
export 'presentation/detalhes/orcamento_detalhes_page.dart';
export 'presentation/lista/orcamentos_lista_page.dart';
export 'presentation/orcamentos_controller.dart';
export 'presentation/orcamentos_routes.dart';
export 'presentation/orcamentos_ui.dart';
export 'presentation/pdf/orcamento_pdf_page.dart';
export 'presentation/wizard/orcamento_controller.dart';
export 'presentation/wizard/orcamento_controller_state.dart';
export 'presentation/wizard/orcamento_wizard_page.dart';
