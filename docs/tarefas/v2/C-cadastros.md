---
trilha: V2-C
titulo: Cadastros de materiais e da empresa
status: em andamento     # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/v2-c-cadastros
depende_de: V2-F2
---

# V2-C: materiais e dados da empresa

**Base:** prompt v2 §3.1, §3.2 e §6 (material).
**Decisões:** D-26 e D-31.
**Arquivos:** a linha da V2-C na
[`orquestracao.md` §3](../../orquestracao.md#3-o-que-cada-trilha-possui),
com os pontos de contato listados lá.

## Checklist
- [ ] Materiais, a partir de "Mais":
  - lista com busca, mostrando nome, unidade, preço de referência e
    situação;
  - filtro Ativos/Todos;
  - novo e editar: nome, unidade m²/m³, preço de referência maior que
    zero;
  - inativar e reativar, sem excluir;
  - ao tentar mudar a unidade de um material já usado, orientar a criar
    outro e inativar o atual (prompt §3.1).
- [ ] Atalho "Cadastrar material", usado pela composição de peças (V2-A).
      Volta com o material novo selecionado; o contrato de rota vem da F2.
- [ ] Dados da empresa: nome/razão social, CPF/CNPJ, telefone, endereço e
      e-mail opcional, com validação. Salvar libera o "Novo orçamento".

## Testes
- Novo, editar, inativar e reativar.
- Material inativo não aparece em novas seleções.
- Editar o material não muda um orçamento salvo.
- Empresa incompleta bloqueia o novo orçamento.
- Telas a 360 dp, no claro e no escuro.
