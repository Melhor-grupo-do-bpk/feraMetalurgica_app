---
trilha: F1
titulo: Fundação das telas
status: concluída       # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code)
branch: feat/f1-fundacao-telas
depende_de: —
---

# F1: Fundação das telas

**Objetivo:** deixar pronto tudo o que mais de uma trilha usa, para que T2 a T7
não precisem editar arquivos em comum. Ao fim da F1, o app abre todas as
rotas (com stubs), tem dados de exemplo e o CI está verde.

Esta é a única trilha que mexe em `core/`, `domain/`, `data/`, barrels,
`main.dart` e `pubspec.yaml`.

## O que ficou disponível para as trilhas

| Precisa de… | Use |
|---|---|
| Navegar | `AppRoutes.*` e `rootNavigatorKey` (`core/router/app_routes.dart`) |
| Lista/escrita de orçamentos | `orcamentosProvider` (`salvar`, `excluir`), `orcamentoPorIdProvider(id)` |
| Produtos do catálogo | `produtosCatalogoProvider`, `produtoPorIdProvider(id)` |
| Tarefas | `tarefasProvider` (`salvar`, `excluir`, `alternarConcluida`), `tarefaPorIdProvider(id)` |
| Rótulos e tons de status/tipo | `StatusOrcamentoUi` (`label`, `labelFiltro`, `tone`), `OrcamentoUi.numeroFormatado`, `TipoTarefaUi` (`label`, `labelFiltro`, `tone`, `corDestaque`) |
| Próximo número de orçamento | `proximoIdOrcamento(lista)` |
| Ids de cliente, item e tarefa | `gerarId()` (`core/utils/id_generator.dart`) |
| Datas | `formatarData`, `formatarHora`, `formatarDiaCurto`, `formatarMesAno` (`core/utils/date_format.dart`) |
| Máscaras | `TelefoneInputFormatter`, `CpfCnpjInputFormatter`, `formatarTelefone`, `formatarCpfCnpj` (`core/utils/input_formatters.dart`) |
| Validação de formulário | `validarObrigatorio`, `validarTelefone`, `validarCpfCnpj`, `validarEmail`, `cpfValido`, `cnpjValido`, `somenteDigitos` (`core/utils/validators.dart`) |
| PF/PJ | `cliente.ehPessoaJuridica` |
| Validade e emissor | `AppConstants.validadeOrcamentoDias`, `AppConstants.emissor*` |
| Stub da sua tela | O arquivo `*_page.dart` já existe com a assinatura final; substitua o corpo do `build` |

## Checklist

### 1. Dependências (D-14)
- [x] `pubspec.yaml`: `uuid`, `url_launcher`, `flutter_localizations` (SDK)
      e o asset `assets/images/catalogo/` (pasta com `.gitkeep`).
- [x] `<queries>` (intent `https`) no `AndroidManifest.xml` e
      `LSApplicationQueriesSchemes` (`https`, `whatsapp`) no `Info.plist`.

### 2. `core/`
- [x] `utils/id_generator.dart`: `gerarId()` (D-09).
- [x] `utils/date_format.dart`. Os nomes de dia e mês são escritos à mão
      para reproduzir o Figma ("Qua, 11 Out"), então **não** é preciso
      chamar `initializeDateFormatting`.
- [x] `utils/input_formatters.dart`: máscaras de telefone e CPF/CNPJ.
- [x] `utils/validators.dart`: validadores de formulário (lista acima).
- [x] `LocalJsonStorage.exists` (D-17).
- [x] `AppConstants.validadeOrcamentoDias` e `emissor*`, com
      `TODO(cliente)` (D-04).
- [x] `router/app_routes.dart` com `AppRoutes` e `rootNavigatorKey`, sem
      importar features. `app_router.dart` só compõe as rotas das features e
      reexporta `app_routes.dart` (D-11, D-12).
- [x] `PlaceholderPage` ganhou `onBack`, usado pelos stubs de telas cheias.

### 3. Domínio e dados
- [x] `Tarefa.descricao` e `Tarefa.orcamentoId` (D-05), com o seed
      atualizado: a revisão aponta para o #00482.
- [x] `Cliente._()` e `ehPessoaJuridica` (D-23).
- [x] `proximoIdOrcamento` (D-09).
- [x] `catalogoSeed` com `fotoPath` em `assets/images/catalogo/<id>.jpg`.
- [x] Seed de orçamentos com todos os status: #00480 rascunho
      (R$ 4.200,00), #00479 enviado (Construtora Apex, R$ 15.200,00) e
      #00478 recusado. O #00481 ganhou um item.

### 4. Controllers e extensões de UI
- [x] `Orcamentos`, `ProdutosCatalogo` e `Tarefas` (`keepAlive`), mais os
      providers `*PorId`.
- [x] `orcamentos_ui.dart` e `cronograma_ui.dart`. O catálogo não
      precisou de um.

### 5. Rotas e stubs (D-11, D-12)
- [x] `<feature>_routes.dart` em orcamentos, catalogo, cronograma,
      dashboard e mais. Os barrels exportam rotas, controllers, extensões e
      páginas.
- [x] Stubs: `OrcamentosListaPage`, `OrcamentoDetalhesPage`,
      `OrcamentoWizardPage`, `OrcamentoPdfPage`, `CatalogoPage`,
      `CronogramaPage` e `TarefaFormPage`.
- [x] `features/mais/`: `MaisPage` real, com "Cronograma" (D-13).

### 6. `main.dart`
- [x] `locale` pt-BR, `GlobalMaterialLocalizations.delegates`.
- [x] `popularDadosIniciais(storage, incluirExemplos: kDebugMode)` (D-17).

### 7. Testes (51 → 106)
- [x] Unitários: `id_generator`, `date_format`, `input_formatters`,
      `validators`, `local_json_storage`, `popular_dados_iniciais`,
      `cliente`, `tarefa_json`, `proximoIdOrcamento`, e os 3 controllers.
- [x] Widget: `app_router_test.dart` (todas as rotas de D-11, parâmetros,
      voltar, Mais → Cronograma) e `app_shell_test.dart` atualizado.

### 8. Documentação
- [x] `README.md` raiz e `CLAUDE.md`/`.cursorrules` atualizados.

## Observações para as trilhas
- Use o Flutter 3.47.1 do FVM (ver `docs/orquestracao.md` §2); com ele,
  `dart run build_runner build --delete-conflicting-outputs` funciona. Se
  o `build_runner` avisar que ignora a flag, rode sem ela.
- Para testar a navegação com as telas reais, use `feraAppDeTeste()`
  (`test/widget/fera_app_de_teste.dart`): o app inteiro com armazenamento
  em memória e os dados de exemplo.
- Os testes de widget que abrem uma tela que lê providers devem sobrescrever
  o provider do repositório (`orcamentoRepositoryProvider.overrideWithValue`)
  com `InMemoryJsonStorage` ou mock, porque `path_provider` não existe em
  teste.
- `test/widget/dashboard_page_test.dart` ainda testa o dashboard
  provisório; a T4 o reescreve.
