---
trilha: F1
titulo: Fundação das telas
status: pendente        # pendente | em andamento | em revisão | concluída
responsavel: —
branch: feat/f1-fundacao-telas
depende_de: —
---

# F1: Fundação das telas

**Objetivo:** deixar pronto tudo o que mais de uma trilha usa, para que T2 a T7
não precisem editar arquivos em comum. Ao fim da F1, o app abre todas as
rotas (com stubs), tem dados de exemplo e o CI está verde.

Esta é a única trilha que mexe em `core/`, `domain/`, `data/`, barrels,
`main.dart` e `pubspec.yaml`.

## Checklist

### 1. Dependências (D-14)
- [ ] `pubspec.yaml`: adicionar `uuid`, `url_launcher` e
      `flutter_localizations` (SDK), e o asset `assets/images/catalogo/`
      (criar a pasta com `.gitkeep`).
- [ ] Configurar o `url_launcher` para consultar o WhatsApp:
      `<queries>` no `AndroidManifest.xml` (intent `https`) e
      `LSApplicationQueriesSchemes` (`https`, `whatsapp`) no `Info.plist`.

### 2. `core/`
- [ ] `utils/id_generator.dart`: `String gerarId()`, UUID v4 (D-09).
- [ ] `utils/date_format.dart`: `formatarData` (`dd/MM/yyyy`),
      `formatarHora` (`HH:mm`), `formatarDiaCurto` (`Qua, 11 Out`) e
      `formatarMesAno` (`Outubro 2023`), todos com locale `pt_BR`.
- [ ] `utils/input_formatters.dart`: `TelefoneInputFormatter`
      (`(99) 99999-9999` ou `(99) 9999-9999`) e `CpfCnpjInputFormatter`
      (alterna a máscara pelo número de dígitos).
- [ ] `utils/validators.dart`: `somenteDigitos`, `validarCpf`,
      `validarCnpj` (dígitos verificadores), `validarCpfCnpj`,
      `validarTelefone` (10 ou 11 dígitos) e `validarEmail`. Assinatura
      compatível com `TextFormField.validator`: `String? Function(String?)`,
      com a mensagem de erro em pt-BR.
- [ ] `utils/local_json_storage.dart`: `Future<bool> exists(String
      fileName)` (D-17).
- [ ] `constants/app_constants.dart`: `validadeOrcamentoDias` e
      `emissor*` (D-04), com `TODO(cliente)`.
- [ ] `router/app_router.dart`: `rootNavigatorKey`, rotas e helpers em
      `AppRoutes` exatamente como em D-11 (`novoOrcamento({produtoId})`,
      `detalhesOrcamento(id)`, `editarOrcamento(id)`, `pdfOrcamento(id)`,
      `cronograma`, `tarefa({id})`). O router só compõe as rotas das
      features (D-12).

### 3. Domínio e dados (rodar o build_runner depois)
- [ ] `Tarefa`: adicionar `String? descricao` e `String? orcamentoId`
      (D-05). Atualizar `cronogramaSeed` com as descrições do Figma, e a
      tarefa "Revisar orçamento #00482" com `orcamentoId: '00482'`.
- [ ] `Cliente`: `const Cliente._()` + getter `ehPessoaJuridica` (D-23).
- [ ] `calculo_orcamento.dart`: `proximoIdOrcamento(List<Orcamento>)` (D-09).
- [ ] `catalogoSeed`: `fotoPath: 'assets/images/catalogo/<id>.jpg'` em
      cada produto (as imagens chegam na T6; até lá vale o placeholder).
- [ ] Se faltar, adicionar ao seed de orçamentos um em `rascunho`, um
      `enviado` e um `recusado`, para que todos os filtros tenham dados.

### 4. Controllers (presentation, compartilhados)
- [ ] `orcamentos/presentation/orcamentos_controller.dart`: `Orcamentos`
      (`build`, `salvar`, `excluir`) + `orcamentoPorId(id)` (ver
      `03-padroes.md` §2).
- [ ] `catalogo/presentation/catalogo_controller.dart`: `ProdutosCatalogo`
      (`build`) + `produtoPorId(id)`.
- [ ] `cronograma/presentation/cronograma_controller.dart`: `Tarefas`
      (`build`, `salvar`, `excluir`, `alternarConcluida(id)`) +
      `tarefaPorId(id)`.
- [ ] Extensões de UI (`<feature>_ui.dart`): `StatusOrcamentoUi` (`label`,
      `variant` do `StatusChip`) e `TipoTarefaUi` (`label`, cor de
      destaque via `context.colors`).

### 5. Rotas e stubs (D-11, D-12)
- [ ] `<feature>/presentation/<feature>_routes.dart` em orcamentos,
      catalogo, cronograma, dashboard e mais, exportados pelos barrels.
- [ ] Stubs (cada um retorna um `PlaceholderPage` com o título da tela e
      aceita os parâmetros finais):
  - `orcamentos/presentation/lista/orcamentos_lista_page.dart`:
    `OrcamentosListaPage()`
  - `orcamentos/presentation/detalhes/orcamento_detalhes_page.dart`:
    `OrcamentoDetalhesPage(orcamentoId:)`
  - `orcamentos/presentation/wizard/orcamento_wizard_page.dart`:
    `OrcamentoWizardPage(orcamentoId:?, produtoId:?)`
  - `orcamentos/presentation/pdf/orcamento_pdf_page.dart`:
    `OrcamentoPdfPage(orcamentoId:)`
  - `catalogo/presentation/catalogo_page.dart`: `CatalogoPage()`
  - `cronograma/presentation/cronograma_page.dart`: `CronogramaPage()`
  - `cronograma/presentation/tarefa_form/tarefa_form_page.dart`:
    `TarefaFormPage(tarefaId:?)`
- [ ] `features/mais/` (D-13): `MaisPage` real, uma lista com "Cronograma"
      que abre `AppRoutes.cronograma`, mais o barrel e as rotas.

### 6. `main.dart`
- [ ] `initializeDateFormatting('pt_BR')`, `locale: Locale('pt', 'BR')`,
      `localizationsDelegates` e `supportedLocales`.
- [ ] Seeds na primeira execução (D-17).

### 7. Testes
- [ ] Unitários: `id_generator`, `date_format`, `input_formatters`,
      `validators`, `LocalJsonStorage.exists`, `proximoIdOrcamento`,
      `Cliente.ehPessoaJuridica`, JSON da `Tarefa` com os campos novos, e os
      3 controllers (com os mocks de `test/mocks/`).
- [ ] Widget: `app_shell_test` passando, e cada rota de D-11 abrindo sem
      erro (`test/widget/app_router_test.dart`).

### 8. Documentação
- [ ] Atualizar o "Estrutura de pastas" e o "Features" do `README.md` raiz
      (feature `mais`, link para `docs/`).
- [ ] Marcar como **implementados** os itens "(F1)" do `CLAUDE.md`.

## Critério de aceite
- Todas as rotas de D-11 navegáveis. A aba Mais abre o Cronograma (stub).
- Em debug, um app recém-instalado já tem orçamentos, produtos e tarefas.
- CI verde. Nenhum `TODO` sem dono além dos `TODO(cliente)` documentados.
