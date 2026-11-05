# Orquestração: desenvolvimento paralelo por agentes (rodada v2)

Este arquivo define **como** as trilhas da rodada v2 são executadas, cada
uma por um agente de IA na sua própria branch e worktree, e como o trabalho
é integrado. Ele é mantido **só pelo orquestrador**; agentes de trilha leem,
não editam. A rodada anterior (telas v1) está em
[`historico/orquestracao-telas-v1.md`](historico/orquestracao-telas-v1.md).

O **quê** desta rodada está em [`v2-plano.md`](v2-plano.md) e em
[`prompt-modulo-orcamento-v2.md`](prompt-modulo-orcamento-v2.md). As
decisões D-26 a D-42 em [`02-decisoes.md`](02-decisoes.md) valem sobre o
prompt quando divergem dele (ex: Riverpod, edição, status).

Precedência: nesta rodada, este arquivo vale sobre a seção 6 ("Git e PR")
de [`03-padroes.md`](03-padroes.md) e sobre a seção "Mudanças fora da sua
trilha" de [`04-plano.md`](04-plano.md). As tarefas da rodada anterior em
`tarefas/*.md` são histórico; as desta rodada estão em
[`tarefas/v2/`](tarefas/v2/). Se algo aqui parecer contradizer o
`CLAUDE.md`, pare e pergunte.

## 1. Branches e worktrees

- **Branch de integração:** `integracao/v2`, criada a partir da `main` com o
  planejamento desta rodada. Nada vai para a `main` sem OK explícito do
  responsável, e sempre por PR com o CI verde.
- **Worktrees:** dentro do repositório, em `worktrees/<ID>/` (ex:
  `worktrees/V2-F1/`). A pasta `worktrees/` está no `.gitignore`. O checkout
  principal fica na `integracao/v2` e é do orquestrador.
- O projeto Flutter de cada worktree fica em
  `worktrees/<ID>/fera_metalurgica_app/`.

| ID | Tarefa | Branch | Depende de | Situação |
|---|---|---|---|---|
| V2-F1 | [Domínio e cálculo](tarefas/v2/F1-dominio-calculo.md) | `feat/v2-f1-dominio` | — | integrada |
| V2-F2 | [Persistência e troca do modelo](tarefas/v2/F2-persistencia.md) | `feat/v2-f2-persistencia` | F1 integrada | integrada |
| V2-A | [Wizard: produtos e peças](tarefas/v2/A-produtos-pecas.md) | `feat/v2-a-produtos` | F2 integrada | integrada |
| V2-B | [Wizard: cliente, valores e prévia](tarefas/v2/B-cliente-valores-previa.md) | `feat/v2-b-cliente-valores` | F2 integrada | integrada |
| V2-C | [Cadastros](tarefas/v2/C-cadastros.md) | `feat/v2-c-cadastros` | F2 integrada | integrada |
| V2-D | [Orçamentos salvos](tarefas/v2/D-orcamentos-salvos.md) | `feat/v2-d-salvos` | F2 integrada | integrada |
| V2-E | [Agenda](tarefas/v2/E-agenda.md) | `feat/v2-e-agenda` | F2 integrada | integrada |
| V2-G | [Acabamento](tarefas/v2/G-acabamento.md) | `feat/v2-g-acabamento` | A a E integradas | integrada |

A worktree de uma trilha só é criada (a partir da `integracao/v2`) quando
todas as dependências dela estão integradas.

## 2. Ambiente

- **Flutter 3.47.1** (fixado em `.fvmrc`). O `flutter` do PATH desta máquina
  é outra versão e quebra o `pub get`. Use o SDK do FVM pelo caminho
  completo: `C:\Users\felip\fvm\versions\3.47.1\bin\flutter` e
  `...\bin\dart` (no Git Bash: `/c/Users/felip/fvm/versions/3.47.1/bin/`).
- Primeira vez na worktree (dentro de `fera_metalurgica_app/`):
  `flutter pub get` e `dart run build_runner build --delete-conflicting-outputs`.
- Fim de linha: LF (`.gitattributes`). Não converta para CRLF.
- **Nunca commite** `.fvmrc`, `.fvm/`, `*.g.dart`, `*.freezed.dart` nem
  arquivos de IDE. Se o `pub get` alterar algo em `windows/`, `android/`,
  `ios/` ou no `pubspec.lock` sem você ter mudado o `pubspec.yaml`, não
  commite: avise no relatório.

## 3. O que cada trilha possui

Caminhos relativos a `fera_metalurgica_app/`. Uma trilha só cria ou altera
arquivos da sua linha, mais o próprio arquivo em `docs/tarefas/v2/` e
`docs/handoffs/v2/<ID>.md`.

| ID | Arquivos (posse exclusiva) |
|---|---|
| V2-F1 | **Só arquivos novos**: `lib/core/domain/**`; `lib/features/orcamentos/domain/v2/**`; `lib/features/materiais/{materiais.dart,domain/**}`; `lib/features/empresa/{empresa.dart,domain/**}`; `lib/features/clientes/{clientes.dart,domain/**}`; `test/unit/v2/**`. Além disso, a seção "Domínio do negócio" do `CLAUDE.md` e do `.cursorrules` (ver tarefa). |
| V2-F2 | Qualquer arquivo (roda sozinha, entre a F1 e as trilhas paralelas). |
| V2-A | `lib/features/orcamentos/presentation/wizard/etapa_produtos.dart` e arquivos novos em `wizard/produto/**`; testes novos em `test/widget/orcamentos/wizard/etapa_produtos*_test.dart`. Na `wizard_teste_helpers.dart`, só a linha do produto em `preencherStub` (ver abaixo). |
| V2-B | Em `lib/features/orcamentos/presentation/wizard/`: `etapa_cliente.dart`, `etapa_valores.dart`, `etapa_previa.dart`, `orcamento_wizard_page.dart`, `wizard_dialogos.dart` (hoje `core/widgets/confirmar_acao.dart`) e arquivos novos em `wizard/previa/**`. Testes: `test/widget/orcamentos/wizard/{orcamento_wizard_page_test,wizard_fluxo_completo_test}.dart` e testes novos em `test/widget/orcamentos/wizard/etapa_{cliente,valores,previa}*_test.dart`. Na `wizard_teste_helpers.dart`, as etapas 1, 3 e 4 de `preencherStub`. |
| V2-C | `lib/features/materiais/presentation/{lista,form}/**`, `lib/features/materiais/presentation/materiais_ui.dart` e `lib/features/empresa/presentation/empresa_page.dart`, mais arquivos novos nessas pastas; testes novos em `test/widget/{materiais,empresa}/**`. |
| V2-D | `lib/features/orcamentos/presentation/{lista,detalhes,pdf}/**`, `lib/features/orcamentos/data/{pdf,whatsapp}/**`, `lib/features/orcamentos/domain/mensagem_whatsapp.dart` e `lib/features/dashboard/presentation/**` (exceto `dashboard_routes.dart`). Testes: `test/widget/orcamentos/{lista,detalhes,pdf}/**`, `test/widget/dashboard_page_test.dart` e `test/unit/{dashboard_indicadores,mensagem_whatsapp,orcamento_pdf_builder,whatsapp_launcher}_test.dart`. |
| V2-E | `lib/features/cronograma/presentation/**` (exceto `cronograma_controller.dart`, `cronograma_routes.dart` e `cronograma_ui.dart`); `test/widget/cronograma/**`. |
| V2-G | Qualquer arquivo (roda sozinha, por último). |

Ficam com o orquestrador (pedidos por handoff): `*_controller.dart` (inclui
`wizard/orcamento_controller*.dart`, `clientes_controller.dart` e
`empresa_controller.dart`), `*_routes.dart`, `*_ui.dart` (exceto o
`materiais_ui.dart`, da V2-C), barrels, `domain/**` e `data/**` (exceto o
que está na linha da V2-D), `core/**`, `main.dart`, `test/mocks/**`,
`test/unit/**` (exceto o da V2-D), `test/widget/fera_app_de_teste.dart`,
`test/widget/app_*_test.dart` e `test/widget/telas_pequenas_test.dart`.

**Pontos de contato:**
- **`wizard_teste_helpers.dart`** é dividido por linha: a V2-A troca só o
  passo do produto em `preencherStub` (o botão de teste sai), e a V2-B só
  os passos das etapas 1, 3 e 4. Helpers novos ficam no próprio arquivo de
  teste da trilha. O orquestrador resolve o conflito no merge.
- **`telas_pequenas_test.dart`:** a trilha testa as próprias telas a
  360 dp no próprio teste e pede no handoff as linhas para o
  `telas_pequenas_test`. O orquestrador acrescenta ao integrar.
- **Detalhes do orçamento:** a V2-E implementa `TarefasDoOrcamento` e
  `AgendarTarefaButton`; a V2-D só os posiciona, sem mudar as assinaturas.
- **"Cadastrar material":** a V2-A chama `AppRoutes.material()`; a V2-C
  garante que a tela devolve o id ao salvar.

Arquivos de teste novos que não couberem nessas pastas: peça no handoff.

**Caminhos que a V2-G mudou** (HO-V2-G-04): `wizard/wizard_dialogos.dart`
→ `core/widgets/confirmar_acao.dart`; `wizard/produto/aviso_inline.dart`
→ `wizard/aviso_inline.dart`;
`test/widget/materiais/materiais_teste_helpers.dart` →
`test/widget/core/teste_helpers.dart`;
`test/widget/cronograma/tarefas_atrasadas_test.dart` →
`test/unit/tarefas_atrasadas_test.dart`. A tabela acima mostra a posse
durante a rodada, com os caminhos da época.

## 4. Contratos

- **F1 expõe** os tipos e funções puras da seção 7 do prompt, com as
  adaptações da D-26 a D-30. Os nomes exatos estão na tarefa da F1. A F2 os
  consome sem mudar assinaturas; se precisar, pede por handoff.
- **F2 expõe** (lista completa em [`handoffs/v2/F2.md`](handoffs/v2/F2.md),
  HO-V2-F2-03; tudo pelos barrels das features):
  - **Banco e repositórios** (congelados): `bancoDeDadosProvider`,
    `materialRepositoryProvider`, `empresaRepositoryProvider`,
    `clienteRepositoryProvider`, `orcamentoRepositoryProvider`,
    `tarefaRepositoryProvider`, `unidadeDeTrabalhoProvider` e
    `finalizarOrcamentoServiceProvider`. `normalizarParaBusca` e
    `compararNomes` em `core/utils/texto_busca.dart`.
  - **Providers** (métodos novos por handoff; não renomear nem remover):
    `orcamentosProvider` (`excluir`, `alterarStatus`, `recarregar`),
    `orcamentoPorIdProvider`; `materiaisProvider` (`salvar`, `inativar`,
    `reativar`), `materiaisAtivosProvider`, `materialPorIdProvider`;
    `dadosEmpresaProvider` (`salvar`), `empresaCompletaProvider`;
    `buscaClientesProvider`, `clientePorDocumentoProvider`;
    `tarefasProvider`, `tarefaPorIdProvider`, `tarefasDoOrcamentoProvider`;
    `indicadoresDashboardProvider` (D-32 e D-37) e
    `recentesDashboardProvider`.
  - **Controller da edição (D-28):** `orcamentoControllerProvider`,
    congelado. Estado `EstadoEdicaoOrcamento`; operações `iniciar`,
    `iniciarEdicao`, `selecionarCliente`, `atualizarCliente`, itens e peças
    (adicionar, editar, remover, duplicar), `atualizarValores`, `avancar`,
    `voltar`, `finalizar` e `descartar`. As que adicionam ou editam
    devolvem `List<ErroValidacao>`. Operações novas vão por handoff.
  - **Rotas (`AppRoutes`):** `dashboard`, `orcamentos`, `agenda`, `mais`,
    `materiais`, `empresa`, `novoOrcamento()`, `detalhesOrcamento(id)`,
    `editarOrcamento(id)`, `pdfOrcamento(id)`, `material({id})` (devolve o
    id ao salvar) e `tarefa({id, orcamentoId})`.
  - **Stubs:** cada trilha substitui os seus (tabela da seção 3 e os
    `TODO(V2-x)` no código).
- **Continuam valendo** os da rodada v1: `AppRoutes.*`, `rootNavigatorKey`,
  `agoraProvider` (nunca chame `DateTime.now()` direto), os widgets de
  `core/widgets/` e os utilitários de `core/utils/`.
- **Testes:** `pumpThemed`, `feraAppDeTeste({themeMode, agora,
  semEmpresa})`, `containerDeTeste`, `overridesDeTeste`,
  `bancoComOrcamentos`, `orcamentosGravados`, `bancoDeTeste()` e os
  exemplos de `test/mocks/dados_exemplo.dart`. Banco SQLite em memória.

## 5. Arquivos compartilhados

Fora das fases que podem mexer em qualquer arquivo (F2 e G), só o
orquestrador altera, na `integracao/v2`, a partir dos handoffs:

- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `lib/main.dart`;
- `lib/core/**` (exceto `lib/core/domain/**` durante a F1);
- `lib/features/*/domain/**` e `lib/features/*/data/**`, salvo os arquivos
  novos da F1;
- barrels, `*_routes.dart`, `*_controller.dart`, `*_ui.dart`;
- testes e mocks compartilhados (`test/mocks/*`, `test/widget/core/*`,
  `test/widget/app_*_test.dart`, `test/widget/fera_app_de_teste.dart`);
- `android/`, `ios/`, `windows/`, `web/`, `.github/`, `.gitattributes`,
  `.gitignore`;
- `CLAUDE.md`, `.cursorrules` (exceto o que a F1 atualiza), `AGENTS.md`,
  `README.md`, `docs/0*.md`, `docs/README.md`, `docs/orquestracao.md`,
  `docs/v2-plano.md`, `docs/prompts/**`.

Métodos novos em controllers e decisões `D-xx` novas também vão por handoff:
o orquestrador numera e aplica.

## 6. Handoffs

Cada trilha tem `docs/handoffs/v2/<ID>.md`, editado **só pela própria
trilha**, na branch dela. Serve para:
- pedidos de mudança em arquivo compartilhado ou de outra trilha;
- contratos errados ou insuficientes;
- decisões novas;
- dúvidas que bloqueiam.

Formato (numere `HO-<ID>-01`, `HO-<ID>-02`…):

```markdown
### HO-V2-A-01: <título curto>
- **Tipo:** mudança em compartilhado | contrato | decisão | dúvida
- **Arquivo(s):** caminho
- **O quê:** ...
- **Por quê:** ...
- **Trecho proposto:** ...
- **Enquanto isso:** o que a trilha fez para seguir
```

O orquestrador registra a resposta e o commit na seção 10 deste arquivo.
Agentes não fazem merge da integração na própria branch, salvo pedido
explícito do responsável.

## 7. Commits

- Só na branch da trilha. Sem push, sem merge, sem `rebase`, sem `--force`,
  sem `reset --hard`.
- Conventional Commits em pt-BR, com o ID da trilha como escopo:
  `feat(v2-f1): Dinheiro em centavos`, `test(v2-a): ...`,
  `docs(v2-f1): status em andamento`.
- Commits pequenos e coesos. O primeiro muda `status: em andamento` e
  `responsavel` no arquivo da tarefa.
- Antes de **cada** commit, dentro de `fera_metalurgica_app/`, nesta ordem:
  1. `dart run build_runner build --delete-conflicting-outputs`
  2. `dart format lib test`
  3. `flutter analyze --fatal-infos`
  4. `flutter test`

  Tudo verde. **O app continua compilando e rodando a cada commit** (prompt
  §11.5).

## 8. Checklist de entrega

- [ ] Checklist da tarefa feito, ou o que faltou listado no relatório.
- [ ] Testes exigidos pela tarefa (cenários da seção 9 do prompt, quando
      couber).
- [ ] Os 4 comandos da seção 7 verdes no último commit.
- [ ] Telas conferidas em modo claro e escuro e a 360 dp (trilhas com tela).
- [ ] Nenhum arquivo fora da seção 3 alterado (`git diff --stat
      integracao/v2...HEAD`).
- [ ] `docs/handoffs/v2/<ID>.md` atualizado (ou "Nenhum pedido").
- [ ] `status: em revisão` no arquivo da tarefa.
- [ ] Relatório final (ver `docs/prompts/v2/<ID>.md`).

## 9. Integração

Quando o responsável avisa que uma trilha terminou, o orquestrador:
1. Revisa a branch: o escopo, os contratos e o handoff.
2. Aplica na integração, em commits próprios, os pedidos aceitos.
3. Faz `git merge --no-ff` na `integracao/v2`, marca a tarefa como
   `concluída` e roda os 4 comandos da seção 7.
4. Reporta o resultado e cria as worktrees liberadas.

**Ordem:**
1. F1, depois F2.
2. A, B, C, D e E em paralelo, entrando na ordem em que terminarem.
3. G por último.
4. A `integracao/v2` vai para a `main` por PR, com OK explícito.

**Riscos conhecidos:**
- **F2 é grande:** troca o modelo em todo o app de uma vez e reescreve os
  testes que dependem dele.
- **A e B compartilham o controller da edição,** congelado depois da F2.
  Operações novas vão por handoff.
- **D e E se encontram nos detalhes do orçamento:** a E fornece o widget de
  tarefas do orçamento e o botão "Agendar", e a D só posiciona. A F2 deixa o
  contrato pronto.

## 10. Registro de handoffs

| Handoff | Resposta | Commit na integração |
|---|---|---|
| HO-T8-01 (seed do cronograma em 2023) | Aceito na rodada v2: item 2 da agenda. A F2 gera as datas dos exemplos a partir de `agoraProvider`. | — |
| HO-V2-F1-01 (código `DDMMAA-NN`, não `AAMMDD-NN`) | Aceito: o exemplo aprovado (`281026-03`) é dia-mês-ano. D-30, plano e tarefas corrigidos. | ver log |
| HO-V2-F1-02 a 07, 09 e 11 (detalhes do domínio) | Aceitos, registrados na D-34. | ver log |
| HO-V2-F1-08 (número com ponto) | Aceito, registrado na D-35. | ver log |
| HO-V2-F1-10 (`Material` colide com o widget do Flutter) | Mantido o nome; `hide Material` no import do Flutter nas telas (D-36). | ver log |
| HO-V2-F1-11 (`numeroFormatado` no `03-padroes.md` §4) | Feito pela F2. | merge da F2 |
| HO-V2-F2-01 (`Orcamento.enviadoEm`) | Aceito, registrado na D-37. | ver log |
| HO-V2-F2-02 (decisões da revisão do plano da F2) | Aceitos, registrados na D-38. | ver log |
| HO-V2-F2-03 (contratos e posse sugerida) | Aceito, com a `wizard_teste_helpers.dart` dividida por linha entre A e B e os testes da V2-D listados. Seções 3 e 4. | ver log |
| HO-V2-F2-04 (avisos) | Registrado nos pontos de contato da seção 3. O cartão da lista com `criadoEm` ou `atualizadoEm` fica com a V2-D. | — |
| HO-V2-A-01 (aviso ao sair da etapa 2) | Aplicado: `_podeSairDaEtapa` chama `podeSairDaEtapaProdutos` na etapa 2. | ver log |
| HO-V2-A-02 (contratos usados de B e C) | Aceito. B e C avisadas: `confirmarAcao`, o scroll da página, "Continuar", `UnidadeCobrancaUi.simbolo`, o `pop(id)` do material e os nomes dos materiais de exemplo. | — |
| HO-V2-A-03 (`CurrencyField` com `double`) | Aplicado: o `CurrencyField` saiu e entrou o `CampoDinheiro` (`core/widgets/campo_dinheiro.dart`), vindo do campo da V2-B. A V2-A continua com o `CampoTexto` decimal dela, que recebe o controller de fora; juntar fica para a V2-G. | ver log |
| HO-V2-A-04 (linhas do `telas_pequenas_test`) | Aplicado. | ver log |
| HO-V2-A-05 (conflito na `wizard_teste_helpers.dart`) | Registrado para o merge da V2-B. | — |
| HO-V2-B-01 (`CampoDinheiro` no core) | Aplicado, junto com o HO-V2-A-03. | ver log |
| HO-V2-B-02 (linhas do `telas_pequenas_test`) | Aplicado: os dois diálogos de descarte e a etapa 1 com busca e aviso. | ver log |
| HO-V2-B-03 (exportar a `PreviaOrcamento`) | Aplicado no barrel de `orcamentos`. | ver log |
| HO-V2-B-04 (avisos) | Registrados. O contraste do `TextButton` padrão nos diálogos (`AppTheme`) e o `abrirWizard` comum ficam para a V2-G. | — |
| Revisão do plano da V2-C (material em uso, maiúsculas) | `estaEmUso`/`materialEmUsoProvider` (D-40) e `MaiusculasInputFormatter` no core antes da trilha codar; merge da integração autorizado na branch da C e da D. | `bdee6e6` |
| HO-V2-C-01 (linhas do `telas_pequenas_test`) | Aplicado: a rota do material em edição, o diálogo de inativar e o bloqueio da unidade. | ver log |
| HO-V2-C-02 (avisos) | Registrados. `confirmarAcao` no core e helpers de teste comuns ficam para a V2-G. | — |
| HO-V2-D-01 (diálogos no `telas_pequenas_test`) | Aceito como veio na branch: "Alterar status" virou "Excluir o orçamento?" e "Voltar para criado?". | merge da V2-D |
| HO-V2-D-02 (asserção do total no `wizard_fluxo_completo_test`) | Aceito como veio na branch. | merge da V2-D |
| HO-V2-D-03 (`bancoDeTeste()` compartilhava o banco em memória) | Aplicado: `abrirBancoDeDados(..., instanciaUnica:)`, e o `bancoDeTeste()` abre com `instanciaUnica: false`. | ver log |
| HO-V2-D-04 (avisos) | Registrados. A instabilidade do `app_shell_test` não se repetiu em duas rodadas da suíte na integração. | — |
| HO-V2-E-01 (linhas do `telas_pequenas_test`) | Aplicado: a rota `tarefa(orcamentoId:)` e um teste da folha de atrasadas, que grava antes uma tarefa pendente de anteontem (`abrir(..., preparar:)`). | ver log |
| HO-V2-E-02 (decisões da agenda) | Aceito, registrado na D-41. | ver log |
| HO-V2-E-03 (avisos) | Registrados. A tarefa atrasada no seed de debug não entra: mudaria os cards e os testes que usam os exemplos. | — |
| Revisão do plano da V2-G | TimelineTile só se reproduzisse (reproduziu); fundo `surface` nos diálogos; `CampoTexto` mantido na etapa 2; `currency_format` removido; testes puros da E em `test/unit/`. | merge da V2-G |
| HO-V2-G-01 (escolhas para um D-xx) | Aceito, registrado na D-42. | ver log |
| HO-V2-G-02 (juntados e separados) | Registrado. | — |
| HO-V2-G-03 (`TarefasDoOrcamento` espreme o título a 360 dp) | Aceito como pendência para depois da v2: não transborda e passa no `telas_pequenas_test`. | — |
| HO-V2-G-04 (caminhos que mudaram, ambiente) | Aplicado na seção 3. As licenças do Android ficam com o responsável. | ver log |
