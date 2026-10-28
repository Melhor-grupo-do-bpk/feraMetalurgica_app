# FERA: relatório da sprint (rodada telas-v1)

26/10/2026 · Felipe Drehmer

Três das oito trilhas estão integradas na branch `integracao/telas-v1`:
F1 (fundação), T2 (lista e detalhes) e T3 (wizard). São 167 testes passando
e `flutter analyze --fatal-infos` limpo. As trilhas T4, T5, T6 e T7 estão
liberadas e com worktree pronta; nada foi para a `main` nem para o `origin`
ainda.

## Situação das trilhas

| Trilha | Telas (Figma) | Depende de | Situação |
|---|---|---|---|
| F1 Fundação das telas | infraestrutura + aba Mais | — | integrada |
| T2 Lista e detalhes | 8, 6 | F1 | integrada |
| T3 Wizard de orçamento | 2, 3, 4, 5 | F1 | integrada |
| T5 PDF e WhatsApp | 7 + ações da 6 | T2 | liberada, não iniciada |
| T4 Dashboard | 1 | F1 | liberada, não iniciada |
| T6 Catálogo | 9 | F1 | liberada, não iniciada |
| T7 Cronograma | 10 + formulário de tarefa | F1 | liberada, não iniciada |
| T8 Acabamento | todas | T2 a T7 | aguardando |

Na integração, desde a `main`: 30 commits e cerca de 5.400 linhas novas em
`lib/` e `test/`. Os testes passaram de 106 (F1) para 135 (após a T2) e 167
(após a T3).

## O que foi entregue

**F1, fundação** (base de todas as trilhas)
- Rotas de todas as telas (`AppRoutes`, D-11), com um stub por tela.
- Controllers compartilhados de orçamentos, catálogo e tarefas.
- Utilitários: datas, máscaras de telefone e CPF/CNPJ, validadores e geração
  de ids.
- Dados de exemplo no primeiro uso em modo debug (D-17).
- Aba "Mais" com o menu do Cronograma.

**T2, lista e detalhes de orçamentos** (RF-30 a RF-33 e RF-50 a RF-54)
- Lista com busca por cliente (sem diferenciar maiúsculas nem acentos) ou
  por número, mais os chips de status (D-22).
- Detalhes com:
  - cliente PF/PJ, prazo e validade;
  - itens descritivos, sem preço por item (D-01);
  - card "Valor Final" com WhatsApp, PDF e Editar;
  - menu "Alterar status" (D-06).
- O botão WhatsApp está pronto, mas sem ação: a T5 implementa o envio.

**T3, wizard de orçamento** (RF-20 a RF-27)
- 4 etapas: cliente, itens, custos e resumo. Voltar mantém os dados, e sair
  com alterações pede confirmação (D-07).
- Tipo do serviço vem do catálogo, com a opção "Outro" (D-20). "Usar no
  orçamento" (`?produtoId=`) já cria o primeiro item.
- Orçamento novo recebe o próximo número e o status "Em análise". A edição
  preserva número, data e status.
- O critério de aceite tem teste automático: o orçamento do Figma (João da
  Silva, custos de R$ 5.200,00) termina nos detalhes com R$ 8.450,00 e
  aparece na lista.

## Como estamos trabalhando

Cada trilha é feita por um agente de IA na própria branch e na própria
worktree (`worktrees/<ID>/`). Um orquestrador revisa e integra. As regras
estão em [`docs/orquestracao.md`](../orquestracao.md).

1. O orquestrador cria a worktree quando as dependências da trilha estão
   integradas.
2. O agente lê as regras, apresenta um plano e só codifica depois da
   aprovação.
3. O agente só altera os arquivos da sua trilha. Mudanças em arquivos
   compartilhados (`core/`, controllers, modelos, pubspec) são pedidas no
   handoff (`docs/handoffs/<ID>.md`) e aplicadas pelo orquestrador.
4. Antes de cada commit rodam build_runner, `dart format`,
   `flutter analyze --fatal-infos` e `flutter test`, com o Flutter 3.47.1
   do FVM.
5. O orquestrador revisa o escopo, aplica os handoffs aceitos, faz o merge na
   integração e roda tudo de novo.
6. A integração só vai para a `main` com OK explícito do responsável.

## Correções feitas na integração

| Item | Origem | O que mudou |
|---|---|---|
| Testes de rota e de shell com armazenamento em memória | orquestrador | Os testes que abrem todas as telas passaram a usar dados de exemplo em memória. Sem isso, quebrariam assim que as telas reais substituíssem os stubs. |
| Fim de linha LF (`.gitattributes`) | orquestrador | Eliminou CRLF misturado e diffs falsos do `dart format`. |
| `url_launcher` no registrant do Windows | orquestrador | Deixou de aparecer como alteração a cada `pub get`. |
| Relógio compartilhado (`agoraProvider`) | plano da T3 | Um só provider de "agora" para T3 e T7, que os testes conseguem fixar. |
| `dart format` em 3 arquivos da F1 | HO-T2-03 | Só formatação. |
| Barra de progresso do wizard invisível | HO-T3-02 | Os segmentos tinham altura 0. Corrigido, com teste. |
| CPF e CNPJ inválidos nos orçamentos de exemplo #00482 e #00481 | HO-T3-04 | Trocados por documentos válidos. Sem isso, editar esses orçamentos travava na etapa 1. |

## Pendências

Perguntas para o cliente (provisórias no código, com `TODO(cliente)`):
- [ ] Margem de 62,5% sobre os custos (D-08).
- [ ] Prazo padrão de 15 dias úteis (D-08).
- [ ] Validade de 15 dias e dados do emissor no PDF (D-04).
- [ ] Salvar orçamento como rascunho no wizard (D-07).
- [ ] Permitir orçamento com custos de R$ 0,00 (HO-T3-01). Hoje é permitido.

Adiado para a T8 (acabamento):
- [ ] Cores próprias para o botão de WhatsApp (HO-T2-01).
- [ ] Mover a normalização de acentos da busca para `core/utils` (HO-T2-02).
- [ ] Área de toque de 48 dp nos botões do `ItemCard` (HO-T3-03).
- [ ] Unificar os cartões de orçamento da lista (T2) e do dashboard (T4).
- [ ] Conferir as telas em aparelho real. Até agora a validação visual foi
      feita por capturas em teste, nos modos claro e escuro.

## Próximos passos e riscos

Ordem sugerida: T5 (completa a tela de detalhes), T4, T6 e T7 em paralelo e,
por último, a T8. As quatro não compartilham arquivos entre si.

- **Risco: `orcamentos_controller.dart`.** É o arquivo compartilhado mais
  disputado; pedidos de métodos novos passam pelo handoff.
- **Risco: tela de detalhes.** A T5 altera só o envio por WhatsApp nos
  detalhes, que são da T2. O conflito esperado é pequeno.
- **Fotos do catálogo (T6).** Se houver fotos reais dos produtos da
  empresa, elas devem ser entregues antes da T6. Senão, o agente usa
  imagens livres de direitos.
- **Ida para a `main`.** Ao fim da T8: push da integração e PR, para o CI
  rodar. Precisa de OK explícito.