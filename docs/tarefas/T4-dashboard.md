---
trilha: T4
titulo: Dashboard
status: pendente        # pendente | em andamento | em revisão | concluída
responsavel: —
branch: feat/t4-dashboard
depende_de: F1
---

# T4: Dashboard (Tela 1)

**Requisitos:** RF-10 a RF-14.
**Decisões:** D-03.
**Arquivos:** `dashboard/presentation/**` (exceto `dashboard_routes.dart`),
`test/widget/dashboard_page_test.dart` e `test/unit/dashboard_indicadores_test.dart`.

## Checklist
- [ ] Reescrever `DashboardPage`, que hoje é um placeholder com rótulos
      errados e não usa os componentes de `core/widgets`: `AppTopBar` sem
      voltar, `PrimaryButton(large: true)` "+ Criar orçamento", grade 2×2 de
      `StatCard` com os ícones do Figma, título "Orçamentos Recentes" + "Ver
      todos" (`context.go(AppRoutes.orcamentos)`) e 2 cartões recentes.
- [ ] Provider `indicadoresDashboard` (em `dashboard/presentation/`) que
      combina `orcamentosProvider` e `tarefasProvider` conforme D-03.
      Contagens com 2 dígitos ("08").
- [ ] Cartão recente: `#id • data`, cliente, "Valor Total" e `StatusChip`.
      Toque abre `AppRoutes.detalhesOrcamento(id)`.
- [ ] Estados carregando, erro e "Nenhum orçamento ainda" (com o CTA).

## Testes
- [ ] Unitário: as regras de D-03 (rascunho e recusado não contam; tarefa de
      produção concluída não conta).
- [ ] Widget: atualizar `dashboard_page_test.dart`: os 4 rótulos, os
      números a partir dos mocks, apenas 2 recentes, e o CTA navega.

## Critério de aceite
Igual à Tela 1. Criar um orçamento no wizard atualiza "Orçamentos em
andamento" e os recentes.
