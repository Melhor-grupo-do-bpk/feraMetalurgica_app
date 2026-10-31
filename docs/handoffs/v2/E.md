# Handoff V2-E

Pedidos e dúvidas da trilha V2-E ([`tarefas/v2/E-agenda.md`](../../tarefas/v2/E-agenda.md)).
Editado só pela própria trilha, na branch `feat/v2-e-agenda`. Formato e regras em
[`orquestracao.md` §6](../../orquestracao.md#6-handoffs); as respostas do
orquestrador ficam em [`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

## Pedidos

### HO-V2-E-01: linhas novas no `telas_pequenas_test`
- **Tipo:** mudança em compartilhado
- **Arquivo(s):** `fera_metalurgica_app/test/widget/telas_pequenas_test.dart`
- **O quê:**
  1. Na lista `rotas`, depois de `AppRoutes.tarefa(id: 'tarefa-producao-00124')`:

     ```dart
     AppRoutes.tarefa(orcamentoId: _c),
     ```

  2. Em `sobreposicoes`, a folha das atrasadas. Os dados de teste não têm
     tarefa atrasada (o `cronogramaSeed` só gera hoje e amanhã), então o
     caso precisa gravar uma antes de abrir a agenda. Sugestão: um
     parâmetro `antes` em `abrir`, ou gravar direto no banco de
     `overridesDeTeste`:

     ```dart
     (
       'folha "tarefas atrasadas"',
       AppRoutes.agenda,
       () => [find.text('Ver')],
     ),
     ```

     com, antes do `pumpWidget`, uma tarefa pendente de ontem gravada pelo
     `tarefaRepositoryProvider` (ex: `Tarefa(id: 'atrasada', titulo:
     'Visita na obra', data: <ontem 16h>, tipo: TipoTarefa.visita)`).
- **Por quê:** as telas novas da V2-E ("Agendar", o aviso e a folha) devem
  passar pelo teste das telas pequenas (orquestracao §3, pontos de
  contato).
- **Enquanto isso:** coberto nos testes da trilha, a 360 dp, no claro e no
  escuro, com as diretrizes de contraste e de áreas de toque:
  `cronograma_page_test` (aviso e folha), `tarefas_do_orcamento_test`
  (widget e "Agendar") e `tarefa_form_page_test` ("Agendar"). O aviso não
  aparece com os dados de exemplo, então o `telas_pequenas_test` atual não
  muda e continua verde.

### HO-V2-E-02: decisões da V2-E, aprovadas pelo responsável
- **Tipo:** decisão
- **Arquivo(s):** `docs/02-decisoes.md`
- **O quê:** aprovadas na revisão do plano da V2-E, para registrar num
  `D-xx`:
  1. **"Agendar"** abre a tarefa nova vinculada, com o tipo Produção e o
     título "Produção <código>", usando o `codigo` do orçamento, sem a
     revisão (a tarefa se liga ao orçamento, não à revisão). O título
     acompanha a troca de tipo ("Visita 281026-03") até o operador
     editá-lo. Sem o orçamento (excluído), fica o vínculo e o título vem
     vazio.
  2. **Tarefas do orçamento:** pendentes primeiro, depois as concluídas,
     cada grupo em ordem cronológica, com data e hora. Tocar abre a edição;
     o marcador conclui. Sem tarefas: "Nenhuma tarefa agendada.". O widget
     não tem título próprio: a seção "Agenda" é da V2-D.
  3. **Atrasada:** pendente de um dia anterior ao de hoje (`agoraProvider`).
     Uma tarefa de hoje com a hora já passada não está atrasada.
  4. **Aviso:** no topo da agenda, conta todas as atrasadas, apesar dos
     filtros de tipo. "Ver" abre uma folha (bottom sheet, sem rota) com a
     lista; tocar numa tarefa fecha a folha e seleciona o dia dela.
  5. **Destaque:** faixa e marcador em `colors.error` e a etiqueta
     "ATRASADA" (tom `danger`) no lugar da etiqueta do tipo, na linha do
     tempo e nas tarefas do orçamento.
- **Enquanto isso:** implementado e testado.

### HO-V2-E-03: avisos para a V2-D e o orquestrador
- **Tipo:** aviso
- **O quê:**
  - **V2-D:** as assinaturas `TarefasDoOrcamento(orcamentoId:)` e
    `AgendarTarefaButton(orcamentoId:)` não mudaram. O widget é uma
    `Column` sem rolagem nem `Expanded` na vertical, testado dentro de um
    `ListView` a 360 dp. No carregamento, mostra um
    `CircularProgressIndicator`: um teste da V2-D com `pumpAndSettle`
    precisa que o `tarefasProvider` resolva (como no banco de teste).
  - **`TarefaForm`** (interno, fora do barrel) ganhou `tipoInicial` e
    `codigoOrcamento`. O `TarefaFormPage` só consulta o
    `orcamentoPorIdProvider` numa tarefa nova com `orcamentoId`; edição e
    tarefa nova sem vínculo não esperam orçamento nenhum.
  - **Arquivo novo** `cronograma/presentation/tarefas_atrasadas.dart`
    (regra, `atrasadasProvider` e contagem), interno da feature e fora do
    barrel. Os testes das funções puras ficaram em
    `test/widget/cronograma/tarefas_atrasadas_test.dart`, porque
    `test/unit/` é do orquestrador; pode movê-los ao integrar.
  - **Sugestão, opcional:** uma tarefa pendente de ontem no
    `cronogramaSeed` (exemplos de debug, D-17) mostraria o aviso numa
    instalação nova. Não fiz: `data/` é do orquestrador.
