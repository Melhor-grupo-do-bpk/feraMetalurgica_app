# Plano de desenvolvimento

## Rodada v2 (atual)

O quê e por quê: [`v2-plano.md`](v2-plano.md) e
[`prompt-modulo-orcamento-v2.md`](prompt-modulo-orcamento-v2.md). Execução
(branches, worktrees, posse de arquivos, contratos, handoffs e integração):
[`orquestracao.md`](orquestracao.md), que nesta rodada substitui as seções
"Quem pode tocar em cada arquivo" e "Mudanças fora da sua trilha" abaixo.

```
V2-F1 Domínio e cálculo ──▶ V2-F2 Persistência e adaptação
                              ├── V2-A Wizard: produtos e peças
                              ├── V2-B Wizard: cliente, valores e prévia
                              ├── V2-C Cadastros (materiais e empresa)
                              ├── V2-D Orçamentos salvos, dashboard, PDF e WhatsApp
                              └── V2-E Agenda
                                        (todas) ──▶ V2-G Acabamento
```

| Trilha | Conteúdo | Arquivo |
|---|---|---|
| **V2-F1** | Objetos de valor, modelos, `CalculadoraOrcamento` e validações | [tarefas/v2/F1-dominio-calculo.md](tarefas/v2/F1-dominio-calculo.md) |
| **V2-F2** | SQLite, repositórios, serviço de finalização, controller da edição; catálogo removido e Agenda como aba | [tarefas/v2/F2-persistencia.md](tarefas/v2/F2-persistencia.md) |
| **V2-A** | Etapa 2: produtos e peças | [tarefas/v2/A-produtos-pecas.md](tarefas/v2/A-produtos-pecas.md) |
| **V2-B** | Etapas 1, 3 e 4 e o "Finalizar" | [tarefas/v2/B-cliente-valores-previa.md](tarefas/v2/B-cliente-valores-previa.md) |
| **V2-C** | Materiais e Dados da empresa | [tarefas/v2/C-cadastros.md](tarefas/v2/C-cadastros.md) |
| **V2-D** | Lista, detalhes, dashboard, PDF e WhatsApp | [tarefas/v2/D-orcamentos-salvos.md](tarefas/v2/D-orcamentos-salvos.md) |
| **V2-E** | Agendar, tarefas do orçamento e atrasadas | [tarefas/v2/E-agenda.md](tarefas/v2/E-agenda.md) |
| **V2-G** | Duplicações entre trilhas, acessibilidade, fluxo de ponta a ponta, documentação e APK | [tarefas/v2/G-acabamento.md](tarefas/v2/G-acabamento.md) |

O status de cada trilha fica no cabeçalho do próprio arquivo. F1, F2 e A a
E estão concluídas e integradas na `integracao/v2`; a V2-G é a última. A
`integracao/v2` vai para a `main` por PR.

Os requisitos da v2 estão em [`01-requisitos.md`](01-requisitos.md), e as
pendências com o cliente, no fim deste arquivo.

## Rodada telas-v1 (concluída, histórico)

O conteúdo abaixo é o plano da rodada telas-v1. As trilhas T2 a T8 estão
concluídas; as regras de posse de arquivos valem só como referência.

### Estratégia

Primeiro uma fase **sequencial** (F1) cria tudo o que é compartilhado:
modelos, controllers, rotas, utilitários, dependências e um arquivo vazio
(stub) para cada tela. Depois disso, cada tela vive em arquivos que
**pertencem a uma única trilha**, e as trilhas podem rodar em paralelo sem
editar os mesmos arquivos.

```
F1 Fundação das telas (sequencial, bloqueia todas)
 ├── T2 Lista + Detalhes ──▶ T5 PDF + WhatsApp
 ├── T3 Wizard
 ├── T4 Dashboard
 ├── T6 Catálogo
 └── T7 Mais + Cronograma
                  (todas) ──▶ T8 Acabamento
```

Depois da F1 podem trabalhar até **5 pessoas ou IAs ao mesmo tempo** (T2,
T3, T4, T6 e T7). A T5 começa quando a T2 entrar na `main`.

### Trilhas

| Trilha | Telas | Depende de | Arquivo |
|---|---|---|---|
| **F1** Fundação das telas | infraestrutura + aba Mais | — | [tarefas/F1-fundacao.md](tarefas/F1-fundacao.md) |
| **T2** Lista e detalhes de orçamentos | 8, 6 | F1 | [tarefas/T2-orcamentos-lista-detalhes.md](tarefas/T2-orcamentos-lista-detalhes.md) |
| **T3** Wizard de orçamento | 2, 3, 4, 5 | F1 | [tarefas/T3-wizard.md](tarefas/T3-wizard.md) |
| **T4** Dashboard | 1 | F1 | [tarefas/T4-dashboard.md](tarefas/T4-dashboard.md) |
| **T5** PDF e WhatsApp | 7 + ações da 6 | T2 | [tarefas/T5-pdf-whatsapp.md](tarefas/T5-pdf-whatsapp.md) |
| **T6** Catálogo | 9 | F1 | [tarefas/T6-catalogo.md](tarefas/T6-catalogo.md) |
| **T7** Cronograma | 10 + formulário de tarefa | F1 | [tarefas/T7-cronograma.md](tarefas/T7-cronograma.md) |
| **T8** Acabamento | todas | T2–T7 | [tarefas/T8-acabamento.md](tarefas/T8-acabamento.md) |

O status de cada trilha fica no cabeçalho do próprio arquivo, e só quem
está com a trilha o edita. Assim, este plano não vira ponto de conflito.

### Quem pode tocar em cada arquivo

Caminhos relativos a `fera_metalurgica_app/`. "Congelado" significa que, após
a F1, só muda via "Mudanças fora da sua trilha" (abaixo).

| Arquivos | Dono |
|---|---|
| `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart` | F1, depois **congelado** |
| `lib/core/**` (router, theme, utils, constants, di, widgets) | F1, depois **congelado** |
| `lib/features/*/domain/**`, `lib/features/*/data/**` (exceto abaixo) | F1, depois **congelado** |
| `lib/features/*/<feature>.dart` (barrels) | F1, depois **congelado** |
| `lib/features/*/presentation/*_routes.dart`, `*_controller.dart`, `*_ui.dart` | F1, depois **congelado** (controllers aceitam métodos novos, ver `03-padroes.md` §2) |
| `lib/features/mais/**` | F1 |
| `lib/features/orcamentos/presentation/lista/**`, `.../detalhes/**` | T2 (a T5 edita só os botões WhatsApp e PDF dos detalhes) |
| `lib/features/orcamentos/presentation/wizard/**` | T3 |
| `lib/features/dashboard/presentation/**` | T4 |
| `lib/features/orcamentos/presentation/pdf/**`, `.../data/pdf/**`, `.../data/whatsapp/**`, `.../domain/mensagem_whatsapp.dart` | T5 |
| `lib/features/catalogo/presentation/**` (exceto controller/routes/ui), `assets/images/catalogo/**` | T6 |
| `lib/features/cronograma/presentation/**` (exceto controller/routes/ui) | T7 |
| `test/unit/<arquivo novo>`, `test/widget/<feature>/**`, `test/mocks/<arquivo novo>` | a trilha que cria |
| `docs/tarefas/<trilha>.md` | a própria trilha |
| `docs/02-decisoes.md` | qualquer trilha, **apenas acrescentando** no fim |
| `CLAUDE.md`, `.cursorrules`, `docs/0*.md` | só com acordo do time |

#### Mudanças fora da sua trilha

Precisa mudar algo congelado (um widget novo em `core/widgets`, um método
no repositório, uma constante)?

1. Abra um **PR pequeno e separado**, só com essa mudança, título
   `[core] ...` ou `[<feature>] ...`, explicando qual trilha precisa.
2. Se a mudança alterar o modelo de dados, uma rota ou uma dependência,
   registre antes um `D-xx` em `02-decisoes.md`.
3. Enquanto o PR não entra, faça uma versão privada na pasta da sua tela e
   troque depois do merge.

Isso mantém os PRs das trilhas fáceis de revisar e evita duas versões do
mesmo utilitário (regra 1 do `CLAUDE.md`).

### Pontos de sincronização

- **Fim da F1**: todo mundo dá rebase. A partir daí, a `main` sempre abre
  todas as telas (stubs) e passa no CI.
- **Merge da T2**: libera a T5.
- **Merge de T2 a T7**: libera a T8, que faz a passada de consistência
  visual e a revisão final dos requisitos.

## Pendências com o cliente

As da rodada telas-v1 (margem, prazo, rascunho, validade e emissor) foram
resolvidas pelo modelo da v2 (D-26, D-30, D-38). O que segue em aberto
(custos de material no PDF, mensagem do WhatsApp, layout do PDF, prazo de
entrega, histórico de revisões, lembretes e visão de semana na agenda, logo
e cores) está em
[`relatorios/2026-10-28-perguntas-cliente.md`](relatorios/2026-10-28-perguntas-cliente.md).
Quando alguma for respondida, registre a decisão em `02-decisoes.md` e
atualize a lista.
