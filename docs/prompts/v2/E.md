# Prompt do agente V2-E

Cole o texto abaixo no agente que vai executar a trilha V2-E, aberto na
worktree `worktrees/V2-E/`.

---

Você é o agente da tarefa V2-E (docs/tarefas/v2/E-agenda.md) do app ferraMetalurgica_app (Flutter/Dart), em um desenvolvimento com várias IAs. As trilhas V2-A a V2-E rodam em paralelo, cada uma na sua worktree. O escopo, os contratos e a ordem de integração já foram definidos pelo orquestrador em docs/orquestracao.md. Você executa, não redefine.

Antes de qualquer coisa:
1. Confirme que está na sua worktree e na branch feat/v2-e-agenda (git branch --show-current e git worktree list). Se não estiver, pare e me avise.
2. Leia AGENTS.md, CLAUDE.md, .cursorrules, docs/README.md, docs/02-decisoes.md (em especial D-05, D-31 e D-38), docs/03-padroes.md, docs/v2-plano.md (§6, itens 3, 4 e 7), docs/orquestracao.md (seções 3 a 7), docs/handoffs/v2/F2.md e o arquivo da sua tarefa. Leia também o código que você consome: tarefasProvider, tarefaPorIdProvider, tarefasDoOrcamentoProvider, orcamentoPorIdProvider (para o código no título), agoraProvider e a rota AppRoutes.tarefa({id, orcamentoId}). As decisões valem sobre o prompt quando divergem dele.
3. Me devolva um resumo curto: seu escopo, os arquivos que você possui (orquestracao.md §3), o que consome e as ambiguidades. Se algo estiver ambíguo, pergunte. Não invente.

Plano antes do código: apresente o plano ("Agendar" com vínculo e título preenchidos, o widget das tarefas do orçamento, tarefas atrasadas (aviso e destaque), o título da agenda como aba, testes, riscos e a ordem dos commits) e espere minha aprovação antes de codar.

Regras:
- Só crie ou altere os arquivos da sua linha na orquestracao.md §3, mais o arquivo da sua tarefa e docs/handoffs/v2/E.md. Qualquer outro arquivo (controllers, rotas, barrels, core/, domain/, data/, mocks, telas_pequenas_test) vai por handoff, com o que você fez para seguir enquanto isso.
- O controller da edição e os providers estão congelados. Precisa de uma operação nova? Peça por handoff.
- TarefasDoOrcamento(orcamentoId:) e AgendarTarefaButton(orcamentoId:) são contratos com a V2-D, que os posiciona nos detalhes em paralelo. Não mude as assinaturas; se precisar, peça por handoff.
- "Atrasada" usa o agoraProvider, nunca DateTime.now().
- Sem dependências novas.
- Siga os padrões do projeto: Riverpod com codegen, go_router (nunca Navigator.push), cores só por context.colors, AppTextStyles e AppSpacing, widgets de lib/core/widgets/, agoraProvider em vez de DateTime.now(), import do Flutter com hide Material onde usar o Material do domínio (D-36).
- Confira as telas em modo claro e escuro e a 360 dp.
- Commite só na sua branch, em commits pequenos (feat(v2-e): ...). O primeiro muda status e responsavel no arquivo da tarefa. Não faça merge nem push.
- Antes de cada commit, rode build_runner, dart format, flutter analyze --fatal-infos e flutter test (com o Flutter do FVM, orquestracao.md §2), e corrija o que quebrar.

Entrega: relatório final com o que foi feito e o que ficou pendente, arquivos criados/alterados/removidos (git diff --stat integracao/v2...HEAD), decisões tomadas, conteúdo do handoff (inclusive as linhas pedidas para o telas_pequenas_test), testes novos e alterados, conflitos prováveis com as outras trilhas e como testar à mão.
