---
trilha: T3
titulo: Wizard de orçamento
status: em revisão         # pendente | em andamento | em revisão | concluída
responsavel: Claude (agente T3)
branch: feat/t3-wizard
depende_de: F1
---

# T3: Wizard de novo orçamento (Telas 2, 3, 4 e 5)

**Requisitos:** RF-20 a RF-27.
**Decisões:** D-02, D-07, D-08, D-09, D-10, D-16, D-20, D-21.
**Arquivos:** `orcamentos/presentation/wizard/**` e
`test/widget/orcamentos/wizard/**` (+ `test/unit/orcamento_wizard_controller_test.dart`).

## Checklist

### Controller (D-21)
- [x] `OrcamentoWizardController` (família `({String? orcamentoId, String?
      produtoId})`), com estado: etapa (1 a 4), `Cliente`, `projeto`,
      `List<ItemOrcamento>`, `CustosOperacionais`.
- [x] Na edição, carrega o orçamento existente. Vindo do catálogo, cria o
      1º item com o produto (RF-27).
- [x] `avancar()` / `voltar()` com validação da etapa. `concluir()` gera o
      id (`proximoIdOrcamento`) se for novo, preenche o `projeto` (D-02),
      salva via `orcamentosProvider.notifier.salvar` e retorna o id.

### Telas (`OrcamentoWizardPage` + um widget por etapa)
- [x] Estrutura comum: `AppTopBar` com voltar (volta etapa; na etapa 1,
      confirma o descarte, D-07), título "Novo Orçamento" (ou "Editar
      Orçamento"), "Etapa N de 4: …", `StepProgressBar` e rodapé
      Voltar/Continuar (`PrimaryButton`). `PopScope` para o voltar do
      sistema.
- [x] **Etapa 1**: `Form` com os campos de RF-21, usando
      `TelefoneInputFormatter`, `CpfCnpjInputFormatter` e os validadores de
      `core/utils/validators.dart`. Rótulo "CPF/CNPJ do cliente" (D-10).
- [x] **Etapa 2**: "Nome do projeto" (D-02); formulário de item com tipo do
      serviço (D-20, lê `produtosCatalogoProvider`), A/L/C (números com
      vírgula ou ponto), material, especificações e quantidade. "Adicionar
      Item" (`OutlinedAppButton`). Lista "Itens Adicionados (N)" com
      `ItemCard` (editar carrega o item no formulário; excluir pede
      confirmação).
- [x] **Etapa 3**: 5 `SectionCard` + `CurrencyField` e o card "Resumo de
      Custos" com "Tot. Previsto" ao vivo.
- [x] **Etapa 4**: resumo de RF-24 com o aviso "Visão do Cliente"; nenhum
      custo interno (D-16). "Continuar" chama `concluir()` e depois
      `context.pushReplacement(AppRoutes.detalhesOrcamento(id))`.

### Testes
- [x] Unitário do controller: validação por etapa, adicionar, editar e
      excluir item, `concluir` (id sequencial, projeto padrão, status
      `emAnalise`), e edição preservando `id`, `criadoEm` e `status`.
- [x] Widget: etapa 1 bloqueia o avanço com CPF inválido; etapa 3 atualiza
      o total ao digitar; fluxo completo grava R$ 8.450,00 para custos de
      R$ 5.200,00.

## Critério de aceite
Criar o orçamento do Figma (João da Silva, portão basculante, custos de
R$ 5.200,00) termina nos detalhes com valor final de R$ 8.450,00, e ele
aparece na lista e no dashboard sem reiniciar o app.

## Notas da entrega

- **`StepProgressBar`**: está no lugar, mas os segmentos da F1 têm altura 0
  e a barra não aparece. Correção pedida em HO-T3-02; não exige mudança
  na T3.
- **Concluir na edição**: volta aos detalhes com `context.pop()`, em vez
  de `pushReplacement`, para não empilhar dois detalhes (aprovado pelo
  responsável no plano).
- **Descarte (D-07)**: só pergunta quando algo mudou em relação ao estado
  inicial (novo, vindo do catálogo ou edição).
- **Etapa 3**: aceita total R$ 0,00 (dúvida para o cliente em HO-T3-01).
- **Dashboard no critério de aceite**: o wizard grava pelo
  `orcamentosProvider`, que o dashboard observa (RF-14). Nesta branch o
  dashboard ainda é o stub da F1, então isso só pode ser conferido depois
  da integração com a T4.
