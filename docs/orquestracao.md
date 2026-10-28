# Orquestração: desenvolvimento paralelo por agentes (rodada telas-v1)

Este arquivo define **como** as trilhas T2 a T8 são executadas em paralelo,
cada uma por um agente de IA na sua própria branch e worktree, e como o
trabalho é integrado. Ele é mantido **só pelo orquestrador**; agentes de
trilha leem, não editam.

Precedência: nesta rodada, este arquivo vale sobre a seção 6 ("Git e PR")
de [`03-padroes.md`](03-padroes.md) e sobre a seção "Mudanças fora da sua
trilha" de [`04-plano.md`](04-plano.md). Todo o resto (`CLAUDE.md`,
`01-requisitos.md` a `04-plano.md`, arquivos de `tarefas/`) continua valendo.
Se algo aqui parecer contradizer o `CLAUDE.md`, pare e pergunte.

## 1. Branches e worktrees

- **Branch de integração:** `integracao/telas-v1`, criada a partir da
  `main`. A F1 já foi integrada nela. Nada vai para a `main` (nem para o
  `origin`) sem OK explícito do responsável pelo projeto.
- **Worktrees:** dentro do repositório, em `worktrees/<ID>/` (ex:
  `worktrees/T2/`). A pasta `worktrees/` está no `.gitignore` da raiz: o
  trabalho de cada worktree é versionado **na branch dela**. O checkout
  principal do repositório fica na `integracao/telas-v1` e é do
  orquestrador.
- O projeto Flutter de cada worktree fica em
  `worktrees/<ID>/fera_metalurgica_app/`.

| ID | Tarefa | Branch | Worktree | Depende de | Situação |
|---|---|---|---|---|---|
| F1 | [Fundação das telas](tarefas/F1-fundacao.md) | `feat/f1-fundacao-telas` | — | — | integrada |
| T2 | [Lista e detalhes](tarefas/T2-orcamentos-lista-detalhes.md) | `feat/t2-orcamentos-lista-detalhes` | `worktrees/T2` | F1 | integrada |
| T3 | [Wizard](tarefas/T3-wizard.md) | `feat/t3-wizard` | `worktrees/T3` | F1 | integrada |
| T4 | [Dashboard](tarefas/T4-dashboard.md) | `feat/t4-dashboard` | `worktrees/T4` | F1 | integrada |
| T5 | [PDF e WhatsApp](tarefas/T5-pdf-whatsapp.md) | `feat/t5-pdf-whatsapp` | `worktrees/T5` | T2 integrada | integrada |
| T6 | [Catálogo](tarefas/T6-catalogo.md) | `feat/t6-catalogo` | `worktrees/T6` | F1 | integrada |
| T7 | [Cronograma](tarefas/T7-cronograma.md) | `feat/t7-cronograma` | `worktrees/T7` | F1 | liberada |
| T8 | [Acabamento](tarefas/T8-acabamento.md) | `feat/t8-acabamento` | `worktrees/T8` | T2 a T7 integradas | aguardando |

A worktree de uma trilha só é criada (a partir da `integracao/telas-v1`)
quando todas as dependências dela estão integradas.

## 2. Ambiente

- **Flutter 3.47.1** (fixado em `.fvmrc`). O `flutter` do PATH desta máquina
  é outra versão e quebra o `pub get`. Use o SDK do FVM pelo caminho
  completo: `C:\Users\felip\fvm\versions\3.47.1\bin\flutter` e
  `...\bin\dart` (no Git Bash: `/c/Users/felip/fvm/versions/3.47.1/bin/`).
  Se o `fvm` estiver no PATH, `fvm flutter` / `fvm dart` também servem.
- Primeira vez na worktree (dentro de `fera_metalurgica_app/`):
  `flutter pub get` e `dart run build_runner build --delete-conflicting-outputs`.
- Fim de linha: o repositório usa LF (`.gitattributes`). Não converta
  arquivos para CRLF.
- **Nunca commite** `windows/flutter/generated_*`, `.fvmrc`, `.fvm/`,
  `*.g.dart`, `*.freezed.dart` nem arquivos de IDE. Se o `pub get` alterar
  algo em `windows/`, `android/`, `ios/` ou no `pubspec.lock`, não commite:
  avise no relatório.

## 3. O que cada trilha possui

Caminhos relativos a `fera_metalurgica_app/`. Uma trilha só cria ou altera
arquivos da sua linha (mais o próprio `docs/tarefas/<arquivo>.md` e
`docs/handoffs/<ID>.md`).

| ID | Arquivos (posse exclusiva) |
|---|---|
| T2 | `lib/features/orcamentos/presentation/lista/**`, `lib/features/orcamentos/presentation/detalhes/**`, `test/widget/orcamentos/lista/**`, `test/widget/orcamentos/detalhes/**` (exceto `enviar_whatsapp_test.dart`) |
| T3 | `lib/features/orcamentos/presentation/wizard/**`, `test/widget/orcamentos/wizard/**`, `test/unit/orcamento_wizard_controller_test.dart` |
| T4 | `lib/features/dashboard/presentation/**` (exceto `dashboard_routes.dart`), `test/widget/dashboard_page_test.dart`, `test/unit/dashboard_indicadores_test.dart` |
| T5 | `lib/features/orcamentos/data/pdf/**`, `lib/features/orcamentos/data/whatsapp/**`, `lib/features/orcamentos/domain/mensagem_whatsapp.dart`, `lib/features/orcamentos/presentation/pdf/**`; em `presentation/detalhes/` **apenas** o corpo de `_enviarWhatsApp` e os imports necessários; `test/unit/mensagem_whatsapp_test.dart`, `test/unit/whatsapp_launcher_test.dart`, `test/unit/orcamento_pdf_builder_test.dart`, `test/widget/orcamentos/pdf/**`, `test/widget/orcamentos/detalhes/enviar_whatsapp_test.dart`, `test/mocks/mock_whatsapp_launcher.dart`; em `test/widget/orcamentos/detalhes/orcamento_detalhes_page_test.dart` (da T2) **apenas** remover ou substituir o teste "Enviar WhatsApp ainda não faz nada (T5)" |
| T6 | `lib/features/catalogo/presentation/**` (exceto `catalogo_controller.dart` e `catalogo_routes.dart`), `assets/images/catalogo/**`, `test/widget/catalogo/**` |
| T7 | `lib/features/cronograma/presentation/**` (exceto `cronograma_controller.dart`, `cronograma_routes.dart` e `cronograma_ui.dart`), `test/widget/cronograma/**`, `test/unit/calendario_mes_test.dart` |
| T8 | qualquer arquivo (roda sozinha, depois de todas) |

Arquivos de teste novos que não couberem nessas pastas: peça no handoff.

## 4. Contratos

Todos já existem na `integracao/telas-v1` (criados pela F1). **Não mude
assinaturas.** Os nomes abaixo são os importados pelos barrels
`features/<feature>/<feature>.dart`.

### Expostos por cada trilha

| ID | Expõe (assinatura fixa) |
|---|---|
| T2 | `OrcamentosListaPage()`, `OrcamentoDetalhesPage({required String orcamentoId})`; nos detalhes, um método `_enviarWhatsApp` vazio com `// TODO(T5)`, chamado pelo botão "Enviar WhatsApp", e um `AppTopBar(onBack: ...)` com o botão voltar padrão (usado por `app_router_test.dart`) |
| T3 | `OrcamentoWizardPage({String? orcamentoId, String? produtoId})`; `OrcamentoWizardController` (D-21) é interno à pasta `wizard/` |
| T4 | `DashboardPage()`; provider `indicadoresDashboard` interno a `dashboard/presentation/` |
| T5 | `gerarOrcamentoPdf(Orcamento) → Future<Uint8List>`, `montarMensagemWhatsApp(Orcamento) → String`, `abrirWhatsApp(String numero, String mensagem) → Future<bool>` exposto por provider `@riverpod`, `OrcamentoPdfPage({required String orcamentoId})`. Não entram no barrel (são usados dentro da feature por caminho relativo) |
| T6 | `CatalogoPage()` |
| T7 | `CronogramaPage()`, `TarefaFormPage({String? tarefaId})`; "hoje" derivado de `agoraProvider` |

### Consumidos (da F1, congelados)

| Contrato | Usado por |
|---|---|
| `orcamentosProvider` (`salvar`, `excluir`), `orcamentoPorIdProvider(id)` | T2, T3, T4, T5, T7 |
| `produtosCatalogoProvider`, `produtoPorIdProvider(id)` | T3, T6 |
| `tarefasProvider` (`salvar`, `excluir`, `alternarConcluida`), `tarefaPorIdProvider(id)` | T4, T7 |
| `StatusOrcamentoUi` (`label`, `labelFiltro`, `tone`), `OrcamentoUi.numeroFormatado` | T2, T4, T7 |
| `TipoTarefaUi` (`label`, `labelFiltro`, `tone`, `corDestaque`) | T7 |
| `AppRoutes.*`, `rootNavigatorKey` | todas |
| `proximoIdOrcamento`, `calcularTotalCustos`, `calcularValorFinal`, `Orcamento.valorFinal`, `Cliente.ehPessoaJuridica`, `Medidas.formatada` | T2, T3, T5 |
| `gerarId`, `date_format`, `input_formatters`, `validators`, `formatarMoeda` (`core/utils/`) | T2, T3, T4, T7 |
| `AppConstants` (`validadeOrcamentoDias`, `emissor*`, `margemPadraoPercentual`) | T2, T5 |
| Widgets de `core/widgets/` | todas |
| `agoraProvider` (`core/di/relogio_provider.dart`): data e hora atuais, sobrescrevível nos testes. Nunca chame `DateTime.now()` direto | T3, T7 (e quem precisar de "agora") |
| Testes: `pumpThemed` (`test/widget/core/pump_themed.dart`), `InMemoryJsonStorage` (`test/mocks/fake_local_json_storage.dart`), mocks `mock_*_repository.dart`, `feraAppDeTeste()` (`test/widget/fera_app_de_teste.dart`: o app inteiro com armazenamento em memória e seed) | todas |

## 5. Arquivos compartilhados

Só o orquestrador altera, na `integracao/telas-v1`, a partir dos handoffs:

- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `lib/main.dart`;
- `lib/core/**`;
- `lib/features/*/domain/**` e `lib/features/*/data/**` (exceto os arquivos
  novos reservados à T5);
- barrels (`lib/features/*/<feature>.dart`), `*_routes.dart`,
  `*_controller.dart`, `*_ui.dart`, `lib/features/mais/**`;
- testes e mocks existentes (`test/mocks/*`, `test/widget/core/*`,
  `test/widget/app_*_test.dart`, `test/widget/fera_app_de_teste.dart`,
  `test/unit/*` já existentes), `test/README.md`;
- `android/`, `ios/`, `windows/`, `web/`, `.github/`, `.gitattributes`,
  `.gitignore`;
- `CLAUDE.md`, `.cursorrules`, `AGENTS.md`, `README.md`, `docs/0*.md`,
  `docs/README.md`, `docs/orquestracao.md`, `docs/prompts/**`.

Inclui **adicionar métodos aos controllers** (o que o `03-padroes.md` §2
permitia) e **acrescentar decisões `D-xx`** em `02-decisoes.md`: nesta rodada
ambos vão por handoff, e o orquestrador numera e aplica. Enquanto o pedido
não é aplicado, a trilha segue com o contrato atual (ou com uma versão
privada dentro da pasta dela, que será trocada depois).

## 6. Handoffs

Cada trilha tem `docs/handoffs/<ID>.md`, editado **só pela própria trilha**,
na branch dela. Use para:

- pedidos de mudança em arquivo compartilhado ou de outra trilha;
- contratos que parecem errados ou insuficientes;
- decisões novas propostas (`D-xx`);
- dúvidas que bloqueiam.

Formato de cada entrada (numere `HO-<ID>-01`, `HO-<ID>-02`…):

```markdown
### HO-T3-01: <título curto>
- **Tipo:** mudança em compartilhado | contrato | decisão | dúvida
- **Arquivo(s):** caminho
- **O quê:** ...
- **Por quê:** ...
- **Trecho proposto:**
  ```dart
  ...
  ```
- **Enquanto isso:** o que a trilha fez para seguir (ex: versão privada em
  `wizard/_x.dart`)
```

O orquestrador registra a resposta e o commit na seção 10 deste arquivo
(não no handoff, para não gerar conflito). Trazer para a branch da trilha
uma mudança já aplicada na integração (`git merge integracao/telas-v1`) só
acontece quando o responsável pelo projeto pedir explicitamente; fora isso,
agentes não fazem merge.

## 7. Commits

- Só na branch da trilha. Sem push, sem merge (exceto o caso acima), sem
  `rebase` na integração, sem `--force`, sem `reset --hard`.
- Conventional Commits em pt-BR, com o **ID da trilha** como escopo:
  `feat(t3): etapa 1 do wizard`, `test(t3): ...`, `fix(t3): ...`,
  `docs(t3): status em andamento`.
- Commits pequenos e coesos. O primeiro commit muda `status: em andamento` e
  `responsavel` no arquivo da tarefa.
- Antes de **cada** commit, dentro de `fera_metalurgica_app/`, nesta ordem:
  1. `dart run build_runner build --delete-conflicting-outputs`
  2. `dart format lib test`
  3. `flutter analyze --fatal-infos`
  4. `flutter test`

  Tudo verde. Se o format mudar arquivo de fora da trilha, não commite
  essa mudança (reverta-a) e avise.

## 8. Checklist de entrega

- [ ] RF da tarefa atendidos, ou o que faltou listado no relatório.
- [ ] Testes exigidos pela tarefa e pelo `03-padroes.md` §5.
- [ ] Os 4 comandos da seção 7 verdes no último commit.
- [ ] Tela conferida contra o PDF em `Teste/`, modo claro e escuro.
- [ ] Nenhum arquivo fora da seção 3 alterado (`git diff --stat integracao/telas-v1...HEAD`).
- [ ] Contratos da seção 4 preservados.
- [ ] `docs/handoffs/<ID>.md` atualizado (ou "Nenhum pedido").
- [ ] `status: em revisão` no arquivo da tarefa.
- [ ] Relatório final (ver o prompt da trilha em `docs/prompts/<ID>.md`).

## 9. Integração

Quando o responsável avisa que uma trilha terminou, o orquestrador:

1. Revisa a branch contra este arquivo: escopo (`git diff --stat
   integracao/telas-v1...feat/...`), contratos, handoff.
2. Aplica na integração, em commits próprios, os pedidos aceitos do
   handoff.
3. Faz `git merge --no-ff` da branch na `integracao/telas-v1`, marca a
   tarefa como `concluída` e roda os 4 comandos da seção 7.
4. Reporta conflitos, falhas e pendências, e cria as worktrees que
   ficaram liberadas.

**Ordem:** T2 antes de T5 (a T5 parte da T2 integrada); T3, T4, T6 e T7
entram na ordem em que terminarem (não compartilham arquivos); T8 por
último. Ao fim, a `integracao/telas-v1` só vai para a `main` com OK
explícito.

**Riscos conhecidos:**

- `orcamentos_controller.dart`: T2, T3 e T5 podem pedir métodos novos.
  Pedidos conflitantes são resolvidos pelo orquestrador.
- `detalhes/`: T2 cria, T5 completa só `_enviarWhatsApp`.
- Cartões de orçamento parecidos em T2 (lista) e T4 (recentes): cada um
  fica privado na sua pasta; a T8 unifica em `core/widgets/` se fizer
  sentido.
- `app_router_test.dart` e `app_shell_test.dart` abrem todas as telas reais
  com `feraAppDeTeste()`. Se uma tela nova quebrar esses testes, corrija a
  tela (ex: estado de carregamento infinito), não o teste; se o teste
  estiver errado, peça no handoff.

## 10. Registro de handoffs

| Handoff | Resposta | Commit na integração |
|---|---|---|
| HO-T2-01 (tokens `whatsapp`/`onWhatsapp`) | Adiado para a T8 (sugestão de acabamento). Por enquanto, o card usa tokens existentes. | — |
| HO-T2-02 (normalização de acentos em `core/utils`) | Adiado para a T8, ou antes, se outra trilha precisar de busca (aí vira pedido no handoff dela). | — |
| HO-T2-03 (`dart format` em 3 arquivos da F1) | Aceito e aplicado antes do merge da T2. | `6bfef6e` |
| Revisão do plano da T3 (relógio) | T3 e T7 precisavam de um relógio sobrescrevível. Criei `agoraProvider` compartilhado em `core/di`, para evitar duas versões. | ver log |
| HO-T3-01 (custos R$ 0,00) | Não bloquear. Vai para a lista de perguntas ao cliente da T8. | — |
| HO-T3-02 (`StepProgressBar` com altura 0) | Aceito: `stretch` na `Row` e teste de altura. | `d1a3267` |
| HO-T3-03 (área de toque do `ItemCard`) | Adiado para a T8 (RNF-06). | — |
| HO-T3-04 (CPF/CNPJ inválidos nos seeds) | Aceito: `123.456.789-09` (#00482) e `12.345.678/0001-95` (#00481). | `77b3b34` |
| HO-T4-01 (chip "Em análise" cinza no Figma e comentário do `StatusChip`) | O dashboard usa o mesmo tom da lista. Ajuste do comentário e revisão visual ficam para a T8. | — |
| HO-T5-01 (fonte TTF no PDF) | Adiado para a T8: embutir a fonte em `assets/fonts/` (mexe em `pubspec`), eliminar `textoParaPdf` e voltar o "•" da D-01. | — |
| Relatório da T5: logo | O `logo_fera.png` só tem o "F", sem o texto "FERA METALURGICA" do Figma. Fica para a T8, com o ícone do app. | — |
| Plano da T6: `assets/images/catalogo/` fora do bundle | Aceito: a subpasta foi declarada no `pubspec.yaml` (bug da F1). | `e3bfc02` |
| HO-T6-01 (fotos provisórias da Pexels) | Para a lista do cliente na T8: trocar pelas fotos reais, mantendo os nomes. A foto do portão é residencial, não basculante. | — |
| HO-T6-02 (`CategoriaTag` em `core/widgets` ou junto do `StatusChip`) | Adiado para a T8. | — |
