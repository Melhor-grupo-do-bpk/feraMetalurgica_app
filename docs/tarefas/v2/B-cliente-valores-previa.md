---
trilha: V2-B
titulo: "Wizard: cliente, valores e prévia (etapas 1, 3 e 4)"
status: em revisão   # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/v2-b-cliente-valores
depende_de: V2-F2
---

# V2-B: etapas 1, 3 e 4 e finalizar

**Base:** prompt v2 §3.3, §4 e §6 (cliente, adicionais, desconto,
validade).
**Decisões:** D-26, D-28, D-29 e D-30.
**Arquivos:** a linha da V2-B na
[`orquestracao.md` §3](../../orquestracao.md#3-o-que-cada-trilha-possui),
com os pontos de contato listados lá.

## Checklist
- [x] Etapa 1, cliente:
  - busca por nome, celular ou documento;
  - selecionar preenche uma cópia editável;
  - nome, celular, documento e endereço obrigatórios;
  - mudar o documento de um cliente já selecionado resolve a identidade
    de novo e avisa que pode ser outro cadastro;
  - o cadastro só é criado ou atualizado ao salvar.
- [x] Etapa 3, valores:
  - insumos, impostos, combustível, outros (com descrição obrigatória se
    maior que zero), desconto (no máximo o subtotal), validade opcional em
    dias (mostra a data-limite) e observações;
  - total geral não editável;
  - total zero destacado.
- [x] Etapa 4, prévia: widget separado alimentado só pelos dados do
      orçamento (prompt §4), para o PDF reaproveitar depois.
  - Comercial por produto, com o detalhe das peças disponível na tela.
  - Na edição, mostra o código e a próxima revisão.
- [x] "Finalizar" (ou "Salvar alterações" na edição):
  - bloqueia o clique duplo e mostra o progresso;
  - se falhar, mantém os dados e permite tentar de novo;
  - se der certo, vai para os detalhes.
- [x] Sair do wizard pede confirmação de descarte. Voltar entre as etapas
      não perde dados.

## Testes
- Cliente novo e cliente existente pelo documento.
- Aviso de troca de documento.
- Validações da etapa 3.
- O cenário C chega a R$ 3.630,80.
- Falha de gravação mantém a sessão.
- Clique duplo não cria dois orçamentos.
- Edição gera rev. 2.
