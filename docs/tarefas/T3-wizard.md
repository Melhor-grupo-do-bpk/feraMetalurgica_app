---
trilha: T3
titulo: Wizard de orçamento
status: concluída          # pendente | em andamento | em revisão | concluída
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

## Relatório final

Entregue na branch `feat/t3-wizard` e integrada na `integracao/telas-v1`
(`ccda837`). No último commit da trilha, os 4 comandos de
`orquestracao.md` §7 estavam verdes: build_runner, `dart format` sem
mudanças fora da trilha, `flutter analyze --fatal-infos` limpo e
`flutter test` com 166 testes (15 novos).

### Requisitos

| RF | Situação |
|---|---|
| RF-20 | Feito: 4 etapas, voltar mantém os dados, voltar do sistema (`PopScope`), descarte com confirmação (D-07). |
| RF-21 | Feito: máscaras de telefone e CPF/CNPJ, validadores de `core/utils`, rótulo "CPF/CNPJ do cliente" (D-10). |
| RF-22 | Feito: nome do projeto (D-02), tipo do serviço do catálogo + "Outro" (D-20), A/L/C, material, especificações, quantidade; itens com editar e excluir. |
| RF-23 | Feito: 5 custos e "Tot. Previsto" ao vivo. |
| RF-24 | Feito: resumo com o aviso "Visão do Cliente", sem custos internos (D-16). |
| RF-25 / RF-26 | Feito: novo grava `emAnalise` com `proximoIdOrcamento` e `criadoEm` do `agoraProvider`; edição mantém `id`, `criadoEm` e `status`. |
| RF-27 | Feito: `?produtoId=` cria o 1º item; id inexistente é ignorado. |

Critério de aceite coberto por `wizard_fluxo_completo_test.dart` (app
inteiro): João da Silva, portão basculante, custos de R$ 5.200,00 →
detalhes do #00483 com R$ 8.450,00 → orçamento na lista. O dashboard
observa o mesmo `orcamentosProvider` (RF-14), mas só pode ser conferido
quando a T4 for integrada.

### Decisões tomadas no plano (aprovadas pelo responsável)

- Concluir: orçamento novo usa `pushReplacement` para os detalhes; a
  edição usa `context.pop()`, para não empilhar dois detalhes.
- Descarte (D-07): só pergunta quando o estado mudou em relação ao
  inicial (novo, vindo do catálogo ou edição).
- Item preenchido e não adicionado não entra sozinho; o Continuar da etapa
  2 exige 1 item e mostra um `SnackBar`.
- Etapa 3 aceita total R$ 0,00 (HO-T3-01).
- Ao editar um item: "Salvar Item" e "Cancelar".
- Medidas aceitam vírgula ou ponto, maiores que zero; vazio vira `null`.

Nenhum `D-xx` novo.

### Arquivos

- `lib/features/orcamentos/presentation/wizard/`:
  `orcamento_wizard_page.dart` (substitui o stub),
  `orcamento_wizard_controller.dart`, `orcamento_wizard_state.dart`
  (`@freezed`), `etapa_cliente.dart`, `etapa_itens.dart`, `item_form.dart`,
  `etapa_custos.dart`, `etapa_resumo.dart`, `wizard_campo.dart`,
  `wizard_dialogos.dart`.
- `test/unit/orcamento_wizard_controller_test.dart`;
  `test/widget/orcamentos/wizard/` (`orcamento_wizard_page_test.dart`,
  `wizard_fluxo_completo_test.dart`, `wizard_teste_helpers.dart`).

### Contratos

- Exposto: `OrcamentoWizardPage({String? orcamentoId, String? produtoId})`,
  sem mudança. `OrcamentoWizardController` é interno à pasta `wizard/`
  (família `({String? orcamentoId, String? produtoId})`).
- Consumidos, sem mudança: `orcamentosProvider`, `produtosCatalogoProvider`,
  `agoraProvider`, `proximoIdOrcamento`, `calcularTotalCustos`,
  `Orcamento.valorFinal`, `Medidas.formatada`, `gerarId`, validadores,
  máscaras, `formatarMoeda`, widgets de `core/widgets` e
  `AppRoutes.detalhesOrcamento`.

### Handoffs

| Handoff | Resultado |
|---|---|
| HO-T3-01 (custos R$ 0,00) | Não bloquear; pergunta ao cliente na T8. |
| HO-T3-02 (`StepProgressBar` com altura 0) | Corrigido na integração (`d1a3267`). |
| HO-T3-03 (área de toque do `ItemCard`) | Adiado para a T8 (RNF-06). |
| HO-T3-04 (CPF/CNPJ inválidos nos seeds) | Corrigido na integração (`77b3b34`). |

### Observado depois da entrega

Ao rodar o app no Windows com a janela estreita, a barra de navegação
inferior (`core/widgets/app_bottom_nav_bar.dart:43`, F1) estourou 9,4 px
para a direita (largura disponível de 299 px). Não é do wizard. Sugestão
para a T8: conferir a barra em 320 px de largura.

### Como testar

```bash
flutter test test/unit/orcamento_wizard_controller_test.dart test/widget/orcamentos/wizard/
```

No app (modo debug): Orçamentos → "Novo", João da Silva com um CPF válido
(ex: `529.982.247-25`), item "Portão Basculante" 2,50 × 2,20, custos
2.450 + 1.800 + 350 + 180 + 420. O resumo mostra R$ 8.450,00 e o concluir
abre os detalhes do novo orçamento. Testar também "Editar" nos detalhes e
o descarte ao sair da etapa 1 com dados preenchidos.
