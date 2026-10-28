---
trilha: T7
titulo: Cronograma
status: em revisão     # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/t7-cronograma
depende_de: F1
---

# T7: Cronograma e agenda (Tela 10 + formulário de tarefa)

**Requisitos:** RF-80 a RF-86.
**Decisões:** D-05, D-11, D-14.
**Arquivos:** `cronograma/presentation/**` (exceto
`cronograma_controller.dart`, `cronograma_routes.dart` e `cronograma_ui.dart`)
e `test/widget/cronograma/**`.

## Checklist

### `CronogramaPage` (Tela 10)
- [x] Provider da tela: dia selecionado (padrão: hoje, derivado de
      `agoraProvider` em `core/di/relogio_provider.dart`, que os testes
      sobrescrevem), mês exibido e tipos
      marcados (os 3 por padrão).
- [x] `CalendarioMensal` feito à mão (D-14): cabeçalho "Outubro 2023" com
      ‹ ›, linha D S T Q Q S S, dias de outros meses esmaecidos, dia
      selecionado em pílula escura, ponto (`brand`) nos dias com tarefa
      pendente dos tipos marcados.
- [x] Card "Filtros de tarefas" com 3 `CheckboxListTile` (D-05).
- [x] Atalhos horizontais de dia ("Hoje, 9 Out", "Amanhã, 10 Out", "Qua, 11
      Out"…, 7 dias a partir do selecionado).
- [x] Linha do tempo: seções do dia selecionado e do seguinte ("Hoje" /
      "Amanhã" / `formatarDiaCurto`), com "N tarefas" e itens ordenados
      por hora em `TimelineTile`: hora, título, etiqueta do tipo, descrição
      e "Ver Detalhes" quando há `orcamentoId`. Tocar no círculo chama
      `alternarConcluida`. Concluída fica riscada e esmaecida.
- [x] FAB "+" abre `AppRoutes.tarefa()`. Tocar e segurar um item abre
      `AppRoutes.tarefa(id: ...)`.

### `TarefaFormPage`
- [x] Campos: Título\*, Data\* (`showDatePicker`), Hora\*
      (`showTimePicker`), Tipo\* (3 opções), Descrição e Orçamento
      vinculado (lista de seleção opcional com `#id - cliente`, a partir de
      `orcamentosProvider`).
- [x] Salvar com `tarefasProvider.notifier.salvar` (id novo via `gerarId`).
      Na edição, botão "Excluir" com confirmação.

## Testes
- [x] Widget: com `hoje` fixo em 09/10/2023 e o seed, mostra as seções "Hoje
      (2 tarefas)" e "Amanhã (1 tarefa)"; desmarcar Produção esconde as
      tarefas de produção; tocar no círculo conclui; o formulário valida os
      campos obrigatórios.
- [x] Unitário: a função que monta a grade do mês (o dia 1 cai na coluna
      certa; 5 ou 6 semanas).

## Critério de aceite
Igual à Tela 10 (com o filtro extra de Produção). Uma tarefa criada no
formulário aparece no dia certo e soma em "Pedidos em produção" se for do
tipo produção.
