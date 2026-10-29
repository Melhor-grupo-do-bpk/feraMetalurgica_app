# Orquestração: desenvolvimento paralelo por agentes (rodada v2)

Este arquivo define **como** as trilhas da rodada v2 são executadas, cada
uma por um agente de IA na sua própria branch e worktree, e como o trabalho
é integrado. Ele é mantido **só pelo orquestrador**; agentes de trilha leem,
não editam. A rodada anterior (telas v1) está em
[`historico/orquestracao-telas-v1.md`](historico/orquestracao-telas-v1.md).

O **quê** desta rodada está em [`v2-plano.md`](v2-plano.md) e em
[`prompt-modulo-orcamento-v2.md`](prompt-modulo-orcamento-v2.md). As
decisões D-26 a D-33 em [`02-decisoes.md`](02-decisoes.md) valem sobre o
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
| V2-F2 | [Persistência e troca do modelo](tarefas/v2/F2-persistencia.md) | `feat/v2-f2-persistencia` | F1 integrada | liberada |
| V2-A | [Wizard: produtos e peças](tarefas/v2/A-produtos-pecas.md) | `feat/v2-a-produtos` | F2 integrada | aguardando |
| V2-B | [Wizard: cliente, valores e prévia](tarefas/v2/B-cliente-valores-previa.md) | `feat/v2-b-cliente-valores` | F2 integrada | aguardando |
| V2-C | [Cadastros](tarefas/v2/C-cadastros.md) | `feat/v2-c-cadastros` | F2 integrada | aguardando |
| V2-D | [Orçamentos salvos](tarefas/v2/D-orcamentos-salvos.md) | `feat/v2-d-salvos` | F2 integrada | aguardando |
| V2-E | [Agenda](tarefas/v2/E-agenda.md) | `feat/v2-e-agenda` | F2 integrada | aguardando |
| V2-G | [Acabamento](tarefas/v2/G-acabamento.md) | `feat/v2-g-acabamento` | A a E integradas | aguardando |

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
| V2-A a V2-E | Definido pelo orquestrador ao integrar a F2, nesta seção. A previsão está em cada tarefa. |
| V2-G | Qualquer arquivo (roda sozinha, por último). |

Arquivos de teste novos que não couberem nessas pastas: peça no handoff.

## 4. Contratos

- **F1 expõe** os tipos e funções puras da seção 7 do prompt, com as
  adaptações da D-26 a D-30. Os nomes exatos estão na tarefa da F1. A F2 os
  consome sem mudar assinaturas; se precisar, pede por handoff.
- **F2 expõe** o que as trilhas paralelas consomem: providers dos
  repositórios, o controller da edição (D-28), as rotas novas em
  `AppRoutes` e os stubs de cada tela. A lista definitiva entra aqui quando a
  F2 for integrada.
- **Continuam valendo** os da rodada v1: `AppRoutes.*`, `rootNavigatorKey`,
  `agoraProvider` (nunca chame `DateTime.now()` direto), os widgets de
  `core/widgets/` e os utilitários de `core/utils/`.
- **Testes:** `pumpThemed` e `feraAppDeTeste()`. A F2 adapta o
  `feraAppDeTeste()` ao SQLite em memória.

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
| HO-V2-F1-11 (`numeroFormatado` no `03-padroes.md` §4) | A F2 troca por `codigoExibicao` ao apagar o modelo antigo. | — |
