# Handoff V2-D

Pedidos e dúvidas da trilha V2-D ([`tarefas/v2/D-orcamentos-salvos.md`](../../tarefas/v2/D-orcamentos-salvos.md)).
Editado só pela própria trilha, na branch `feat/v2-d-salvos`. Formato e regras em
[`orquestracao.md` §6](../../orquestracao.md#6-handoffs); as respostas do
orquestrador ficam em [`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

## Pedidos

### HO-V2-D-01: diálogos dos detalhes no `telas_pequenas_test`
- **Tipo:** mudança em compartilhado (já feita, com OK do responsável)
- **Arquivo(s):** `fera_metalurgica_app/test/widget/telas_pequenas_test.dart`
- **O quê:** o diálogo "Alterar status" saiu dos detalhes. A entrada dele
  em `sobreposicoes` foi trocada por estas duas:

  ```dart
  (
    'diálogo "Excluir o orçamento?"',
    AppRoutes.detalhesOrcamento(_c),
    () => [find.byTooltip('Mais opções'), find.text('Excluir')],
  ),
  (
    'diálogo "Voltar para criado?"',
    AppRoutes.detalhesOrcamento(_c),
    () => [
      find.byTooltip('Mais opções'),
      find.text('Marcar como enviado'),
      find.byTooltip('Mais opções'),
      find.text('Voltar para criado'),
    ],
  ),
  ```

  As rotas da lista, dos detalhes, do PDF e do dashboard já estavam em
  `rotas` e não mudaram.
- **Por quê:** criado → enviado é um toque direto no menu ⋮; enviado →
  criado pede confirmação, porque apaga o `enviadoEm` (D-37). Excluir
  também confirma.
- **Enquanto isso:** aplicado na branch, no commit dos detalhes, para a
  suíte ficar verde. Os 8 testes de diálogo e os 45 das rotas de
  orçamentos passam a 360 dp, com contraste e áreas de toque.

### HO-V2-D-02: asserção do `wizard_fluxo_completo_test`
- **Tipo:** mudança em compartilhado (já feita, com OK do responsável)
- **Arquivo(s):** `fera_metalurgica_app/test/widget/orcamentos/wizard/wizard_fluxo_completo_test.dart`
- **O quê:** em "fluxo completo cria o orçamento -01", a conferência do
  total nos detalhes passou de `find.text(r'R$ 1.098,00')` (um só) para o
  valor dentro da linha "Total geral".
- **Por quê:** os detalhes usam a `PreviaOrcamento` (D-39). Um produto sem
  adicionais repete o valor no total do item, no total dos produtos, no
  subtotal e no total geral. O outro teste do arquivo ("editar o exemplo
  C") passou sem mudança: o card de ações deixou de repetir o total, e o
  cabeçalho mostra o código sem o "Nº".
- **Enquanto isso:** aplicado na branch, no commit dos detalhes.

### HO-V2-D-03: `bancoDeTeste()` compartilha o banco em memória
- **Tipo:** aviso
- **Arquivo(s):** `fera_metalurgica_app/test/mocks/banco_de_teste.dart`
- **O quê:** com um banco de `bancoDeTeste()` ainda aberto (ex: o do
  `setUp`), outro aberto por `containerDeTeste()` no mesmo teste enxerga
  os mesmos dados: a lista trouxe os 3 exemplos do `setUp` mais os 2 do
  seed. O comentário do helper diz que cada chamada é independente.
  Parece o `singleInstance` padrão do sqflite com `inMemoryDatabasePath`.
- **Por quê:** testes que misturam os dois helpers podem passar ou falhar
  pela ordem de abertura.
- **Enquanto isso:** o teste de exclusão com a sequência do dia ficou num
  arquivo próprio, sem o `setUp` (`detalhes/excluir_orcamento_test.dart`).
  Sugestão: abrir com `singleInstance: false` no `bancoDeTeste()`.

### HO-V2-D-04: avisos
- **Tipo:** aviso
- **O quê:**
  - **HO-V2-F2-04 fechado:** a lista e os recentes mostram o
    `atualizadoEm`, aprovado pelo responsável, com um comentário no
    cartão.
  - **Agenda ao excluir:** os detalhes invalidam o `tarefasProvider`
    depois do `excluir`. É a solução definitiva, porque o
    `orcamentosProvider` não depende da agenda.
  - **`confirmarAcao`** (`wizard/wizard_dialogos.dart`, da V2-B) é usado
    pelos detalhes. Se ele mudar de lugar na V2-G, o import dos detalhes
    acompanha.
  - **`PreviaOrcamento`** (`wizard/previa/`, da V2-B) é usada pelos
    detalhes com `mostrarPecas` ligado pelo interruptor "Mostrar peças e
    custos", desligado por padrão.
  - **Instabilidade:** numa rodada da suíte completa, os dois casos do
    `app_shell_test` ficaram como "did not complete". Isolado e nas
    rodadas seguintes da suíte, passaram.
