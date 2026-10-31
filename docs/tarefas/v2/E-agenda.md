---
trilha: V2-E
titulo: Agenda
status: em andamento  # pendente | em andamento | em revisão | concluída
responsavel: Claude (agente V2-E)
branch: feat/v2-e-agenda
depende_de: V2-F2
---

# V2-E: melhorias da agenda

**Base:** [`v2-plano.md`](../../v2-plano.md) §6, itens 1, 2, 3, 4 e 7.
**Decisões:** D-05 e D-31.
**Arquivos:** a linha da V2-E na
[`orquestracao.md` §3](../../orquestracao.md#3-o-que-cada-trilha-possui),
com os pontos de contato listados lá.

A F2 já faz os itens 1 (Agenda como aba) e 2 (exemplos com as datas de
hoje).

## Checklist
- [ ] Item 3: "Agendar" a partir do orçamento abre o formulário de tarefa
      com o vínculo e o título preenchidos (ex: "Produção 281026-03"),
      usando a rota `tarefa(orcamentoId:)` da F2.
- [ ] Item 4: widget das tarefas vinculadas a um orçamento (pendentes
      primeiro, com a data), com toque para abrir a tarefa e marcar como
      concluída. A V2-D posiciona o widget nos detalhes.
- [ ] Item 7: tarefas atrasadas, ou seja, pendentes de dias anteriores a
      hoje:
  - um aviso no topo da agenda com a quantidade e um atalho para vê-las;
  - destaque no item.
- [ ] Revisar a agenda depois da troca de aba: título e voltar, sem a seta
      de "Mais".

## Testes
- "Agendar" preenche o vínculo e o título.
- O widget do orçamento mostra só as tarefas dele.
- A contagem de atrasadas usa `agoraProvider`.
- A agenda a 360 dp, no claro e no escuro.
