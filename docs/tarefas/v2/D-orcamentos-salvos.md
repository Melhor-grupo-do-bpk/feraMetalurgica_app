---
trilha: V2-D
titulo: Orçamentos salvos, dashboard, PDF e WhatsApp
status: em revisão   # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/v2-d-salvos
depende_de: V2-F2
---

# V2-D: lista, detalhes, dashboard, PDF e WhatsApp

**Base:** prompt v2 §4 (início e histórico) e §6 (histórico).
**Decisões:** D-26, D-29, D-30, D-32, D-37 e D-39. O PDF e o WhatsApp só
trocam os dados de origem; o redesenho do documento comercial é outra
tarefa (prompt §1).
**Arquivos:** a linha da V2-D na
[`orquestracao.md` §3](../../orquestracao.md#3-o-que-cada-trilha-possui),
com os pontos de contato listados lá.

## Checklist
- [x] Lista:
  - cada orçamento mostra código (com "rev. N"), cliente, data, total
    geral e status;
  - busca por cliente ou código;
  - filtro Todos, Criados e Enviados (D-29).
- [x] Detalhes em leitura, com os **totais gravados**, sem recalcular:
  - produtos com o detalhe das peças;
  - adicionais e desconto, validade e observações;
  - emitente e cliente das cópias.
- [x] Ações nos detalhes:
  - Editar (D-30);
  - Excluir, com confirmação; o código não é reutilizado;
  - alternar o status entre criado e enviado;
  - PDF e WhatsApp.
- [x] Posicionar nos detalhes o widget de tarefas do orçamento e o botão
      "Agendar", que a V2-E implementa (contrato da F2).
- [x] Dashboard: os cards da D-32 e os 2 recentes.
- [x] PDF:
  - emitente e cliente das cópias;
  - código e revisão;
  - produtos com quantidade, preço unitário e total;
  - adicionais e desconto conforme a D-39;
  - validade só se houver.

  Sem custos de material por peça; essa definição é posterior (prompt §4).
- [x] WhatsApp: código, revisão, total geral e validade, se houver. Enviar
      com sucesso marca `enviado`.

## Testes
- A lista e o filtro de status.
- Os detalhes do exemplo C.
- Excluir não reutiliza o código.
- Os cards da D-32 com orçamentos de meses diferentes.
- O PDF é gerado para o exemplo C.
- A mensagem do WhatsApp com e sem validade.
- Enviar muda o status.
