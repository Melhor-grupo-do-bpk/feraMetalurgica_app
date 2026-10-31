# Prompt do agente V2-G

Cole o texto abaixo no agente que vai executar a trilha V2-G, aberto na
worktree `worktrees/V2-G/`.

---

Você é o agente da tarefa V2-G (docs/tarefas/v2/G-acabamento.md) do app ferraMetalurgica_app (Flutter/Dart), em um desenvolvimento com várias IAs. As trilhas V2-F1, V2-F2 e V2-A a V2-E já estão integradas na integracao/v2. Você roda sozinha, por último. O escopo e a ordem de integração já foram definidos pelo orquestrador em docs/orquestracao.md. Você executa, não redefine.

Antes de qualquer coisa:
1. Confirme que está na sua worktree e na branch feat/v2-g-acabamento (git branch --show-current e git worktree list). Se não estiver, pare e me avise.
2. Leia AGENTS.md, CLAUDE.md, .cursorrules, docs/README.md, docs/02-decisoes.md (em especial D-25 e D-26 a D-41), docs/03-padroes.md, docs/prompt-modulo-orcamento-v2.md (§9), docs/orquestracao.md (seções 7 a 10), os handoffs docs/handoffs/v2/{A,B,C,D,E}.md e o arquivo da sua tarefa.
3. Me devolva um resumo curto: seu escopo, o que você vai juntar ou mover entre as trilhas e as ambiguidades. Se algo estiver ambíguo, pergunte. Não invente.

Plano antes do código: apresente o plano (cada item do checklist, com os arquivos que mudam, o que sai e o que entra no core, os testes novos, riscos e a ordem dos commits) e espere minha aprovação antes de codar.

Regras:
- Esta trilha pode alterar qualquer arquivo (orquestracao.md §3), mas só o que a tarefa pede. Não mude regra de negócio, cálculo, esquema do banco nem contratos de provider e controller. Se achar um erro de regra, registre em docs/handoffs/v2/G.md e me avise antes de seguir.
- Ao mover ou juntar widgets, mantenha o comportamento e os textos que os testes conferem. Um teste que precisar mudar de texto ou de chave tem que ter o motivo no commit.
- Sem dependências novas.
- Siga os padrões do projeto: Riverpod com codegen, go_router (nunca Navigator.push), cores só por context.colors, AppTextStyles e AppSpacing, agoraProvider em vez de DateTime.now(), import do Flutter com hide Material onde usar o Material do domínio (D-36).
- Confira as telas em modo claro e escuro e a 360 dp, e desta vez também com o app rodando (flutter run -d windows numa janela estreita), não só nos testes.
- Commite só na sua branch, em commits pequenos (feat(v2-g): ..., refactor(v2-g): ..., docs(v2-g): ...). O primeiro muda status e responsavel no arquivo da tarefa. Não faça merge nem push.
- Antes de cada commit, rode build_runner, dart format, flutter analyze --fatal-infos e flutter test (com o Flutter do FVM, orquestracao.md §2), e corrija o que quebrar.
- O APK de release fica em build/; não o commite. Diga no relatório onde ele ficou.

Entrega: relatório final com o que foi feito e o que ficou pendente, arquivos criados/alterados/removidos (git diff --stat integracao/v2...HEAD), o que foi juntado ou movido para o core, decisões tomadas, conteúdo do handoff, testes novos e alterados, o resultado do teste de ponta a ponta, onde está o APK e como testar à mão.
