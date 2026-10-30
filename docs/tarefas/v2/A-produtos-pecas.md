---
trilha: V2-A
titulo: "Wizard: produtos e peças (etapa 2)"
status: em revisão     # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/v2-a-produtos
depende_de: V2-F2
---

# V2-A: etapa 2, produtos e composição de peças

**Base:** prompt v2 §3.4, §4 ("Comportamento da etapa 2 e da composição"),
§5 e §6.
**Decisões:** D-26 e D-28.
**Arquivos:** a linha da V2-A na
[`orquestracao.md` §3](../../orquestracao.md#3-o-que-cada-trilha-possui),
com os pontos de contato listados lá.

## Checklist
- [x] Etapa 2:
  - lista de produtos com descrição, quantidade, preço base, subtotal e
    total dos produtos;
  - editar, duplicar e remover produto;
  - o rótulo "Preço base de fabricação por produto (sem materiais)" e o
    texto que explica a separação entre preço base e adicionais (prompt
    §6, "Cobrança duplicada").
- [x] Composição do produto, com o formulário da peça do prompt §4:
  - material só entre os ativos, com atalho para cadastrar;
  - preço aplicado copiado, editável, com a unidade, e aviso quando
    difere do cadastro;
  - dimensões desabilitadas até escolher o material, e espessura
    obrigatória só em m³;
  - quantidade por produto.
- [x] Resumo ao vivo por peça (consumo, custo unitário e da linha) e por
      produto (materiais, preço unitário, total). Os números vêm da
      calculadora, nunca de conta na tela.
- [x] Trocar o material: avisa se havia preço ajustado. Se a unidade muda,
      exige revisar as dimensões.
- [x] Limpar o formulário depois de adicionar. Avisar ao avançar com campos
      preenchidos que não foram adicionados. Quantidade zero ou peça
      incompleta bloqueiam avançar.

## Testes
- Widget: os exemplos A e B montados pela interface chegam aos mesmos
  totais da calculadora.
- Troca de unidade, preço ajustado, duplicar e editar sem afetar o
  original.
- Aviso de formulário não adicionado.
- A etapa a 360 dp, no claro e no escuro.
