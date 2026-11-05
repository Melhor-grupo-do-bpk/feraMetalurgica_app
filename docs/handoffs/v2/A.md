# Handoff V2-A

Pedidos e dúvidas da trilha V2-A ([`tarefas/v2/A-produtos-pecas.md`](../../tarefas/v2/A-produtos-pecas.md)).
Editado só pela própria trilha, na branch `feat/v2-a-produtos`. Formato e regras em
[`orquestracao.md` §6](../../orquestracao.md#6-handoffs); as respostas do
orquestrador ficam em [`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

Caminhos relativos a `fera_metalurgica_app/`.

## Pedidos

### HO-V2-A-01: aviso de produto não adicionado ao sair da etapa 2
- **Tipo:** mudança em arquivo de outra trilha (V2-B)
- **Arquivo(s):** `lib/features/orcamentos/presentation/wizard/orcamento_wizard_page.dart`
- **O quê:** na etapa 2, chamar `podeSairDaEtapaProdutos(context, ref)`
  (`wizard/produto/sair_etapa_produtos.dart`) antes de `avancar()` e
  antes de `voltar()`. Se devolver `false`, não sai da etapa.
- **Por quê:** prompt §4 ("Se houver campos preenchidos e não adicionados
  ao avançar, avisar"). O "Continuar" e o "Voltar" são da página, e a
  etapa não tem como interceptá-los. Aprovado pelo responsável na revisão
  do plano: a função vale para avançar e voltar, e o rascunho só é
  descartado com a confirmação do operador.
- **Comportamento da função:**
  - sem produto em montagem, devolve `true`;
  - com o formulário aberto e intocado, fecha-o e devolve `true`;
  - com dados não adicionados, pergunta ("Produto não adicionado" ou
    "Alterações do produto não salvas"), e só descarta e devolve `true`
    se o operador tocar em "Descartar".
- **Trecho proposto:**
  ```dart
  import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/sair_etapa_produtos.dart';

  // _voltar(), antes de `_controller.voltar()`:
  if (estado.etapaAtual > 1) {
    if (estado.etapaAtual == 2 &&
        !await podeSairDaEtapaProdutos(context, ref)) {
      return;
    }
    if (!mounted) return;
    _controller.voltar();
    return;
  }

  // _continuar(), antes de `_controller.avancar()`:
  if (estado.etapaAtual < EstadoEdicaoOrcamento.totalEtapas) {
    if (estado.etapaAtual == 2 &&
        !await podeSairDaEtapaProdutos(context, ref)) {
      return;
    }
    if (!mounted) return;
    if (!_controller.avancar()) _avisarErros();
    return;
  }
  ```
  O voltar do sistema (`PopScope`) já passa por `_voltar()`.
- **Enquanto isso:**
  - a etapa mostra um aviso fixo ("Há um produto em montagem que ainda
    não foi adicionado...") enquanto há dados no rascunho;
  - a função é testada direto, em `etapa_produtos_test.dart`, grupo
    "aviso de produto não adicionado";
  - sem a ligação, avançar com um produto em montagem perde o rascunho,
    que é autoDispose e só existe enquanto a etapa 2 está na tela. Os
    produtos já adicionados ficam na sessão.

### HO-V2-A-02: o que a V2-A usa de arquivos de outras trilhas (viraram contrato)
- **Tipo:** contrato
- **O quê:** a V2-A usa, sem alterar:
  - **V2-B, `wizard/wizard_dialogos.dart`:**
    `confirmarAcao(context, {titulo, mensagem, acao})`, que devolve
    `Future<bool>` e mostra um `AlertDialog` com "Cancelar" e o botão
    [acao]. Usado para remover produto e peça, trocar o material com
    preço ajustado, cancelar o produto e no `podeSairDaEtapaProdutos`.
  - **V2-B, `wizard/orcamento_wizard_page.dart`:**
    - a etapa fica dentro do `SingleChildScrollView` da página, com
      altura livre: o formulário inline não usa `Expanded` nem lista com
      scroll próprio. Se a página deixar de rolar, o formulário precisa
      de outro arranjo;
    - os testes da V2-A e o `preencherStub` usam o texto "Continuar" do
      rodapé (`continuar` em `wizard_teste_helpers.dart`).
  - **V2-B, testes:** `orcamento_wizard_page_test` ("voltar entre etapas
    não perde dados") procura o texto "Produto de teste" na etapa 2, e
    os testes de fluxo conferem R$ 1.098,00. O `preencherStub` novo
    mantém os dois: descrição "Produto de teste", 3 unidades, base
    R$ 150,00 e uma peça de 120 × 60 cm em granito.
  - **V2-C, `materiais/presentation/materiais_ui.dart`:**
    `UnidadeCobrancaUi.simbolo` (`m²`, `m³`), pelo barrel `materiais.dart`.
  - **V2-C, formulário de material:** o contrato de
    `context.push<String>(AppRoutes.material())`, que devolve o id ao
    salvar (ou `null` ao voltar sem salvar). Depois de voltar, a V2-A lê
    o material em `materiaisProvider` (que o `salvar` já recarregou) e só
    o seleciona se estiver ativo. Os testes da V2-A usam uma tela falsa
    nesse caminho, sem depender do formulário real.
  - **V2-C, dados de exemplo:** os nomes `Granito - variedade B - 2 cm`,
    `Madeira - espécie A` e `MDF 15 mm` (`materiais_seed.dart`, F2) são
    usados pelo `preencherStub` e pelos testes da V2-A.
- **Enquanto isso:** nada a fazer. Peço só que B e C sejam avisadas de que
  esses pontos viraram contrato.

### HO-V2-A-03: `CurrencyField` usa `double` (viola a D-26)
- **Tipo:** mudança em compartilhado (`core/`)
- **Arquivo(s):** `lib/core/widgets/currency_field.dart` e
  `test/widget/core/currency_field_test.dart`
- **O quê:** o `CurrencyField` recebe `valorInicial` e devolve
  `onChanged` em `double` (reais), e o formatador de centavos divide por
  100 em `double`. Hoje ele não é usado em `lib/`, só no teste dele.
- **Por quê:** a D-26 proíbe `double` em dinheiro. Por isso a etapa 2 não
  o usa: os campos de dinheiro são `TextField` com
  `Dinheiro.tryParse`.
- **Sugestão:**
  - trocar para `Dinheiro valorInicial = Dinheiro.zero` e
    `ValueChanged<Dinheiro>? onChanged`;
  - no formatador, ler os dígitos como `int` de centavos
    (`Dinheiro(int.parse(digitos))`) e exibir com
    `formatadoSemSimbolo`;
  - ou remover o widget, se nenhuma trilha for usá-lo.

  Observação: `Dinheiro.formatado` e `formatadoSemSimbolo` também passam
  por `double` (`centavos / 100`) para reaproveitar o `NumberFormat`. O
  comentário em `dinheiro.dart` diz que é exato, e é só exibição, mas
  vale conferir o limite de precisão para valores muito grandes.
- **Enquanto isso:** a V2-A não usa o widget. Nada foi alterado no `core/`.

### HO-V2-A-04: linhas para o `telas_pequenas_test.dart`
- **Tipo:** mudança em compartilhado
- **Arquivo(s):** `test/widget/telas_pequenas_test.dart`
- **O quê:** acrescentar à lista `sobreposicoes`:
  ```dart
  (
    'formulário de produto (etapa 2)',
    AppRoutes.editarOrcamento(_c),
    () => [continuar, find.text('Novo produto')],
  ),
  (
    'seletor de material (etapa 2)',
    AppRoutes.editarOrcamento(_c),
    () => [
      continuar,
      find.text('Novo produto'),
      find.byKey(const ValueKey('peca-material')),
    ],
  ),
  ```
- **Por quê:** a etapa 2 já é coberta pelo teste "etapas do wizard em
  360 dp". O formulário inline e o seletor de material só aparecem depois
  de um toque.
- **Enquanto isso:**
  - testei as linhas localmente, sem commitar: 4 testes verdes (claro e
    escuro);
  - a trilha confere a etapa a 360 dp no próprio
    `etapa_produtos_360_test.dart`, que monta um produto inteiro na
    página real do wizard.
  - Se a V2-B mudar a etapa 1 e o "Continuar" deixar de levar à etapa 2
    na edição do exemplo C, as linhas precisam do mesmo ajuste do teste
    "etapas do wizard em 360 dp".

### HO-V2-A-05: aviso sobre a `wizard_teste_helpers.dart`
- **Tipo:** aviso (conflito provável com a V2-B)
- **Arquivo(s):** `test/widget/orcamentos/wizard/wizard_teste_helpers.dart`
- **O quê:**
  - só o passo do produto em `preencherStub` mudou: a linha
    `tocar('Adicionar produto de teste')` virou os passos da interface
    nova, com um comentário;
  - para usar `ValueKey`, entrou também
    `import 'package:flutter/widgets.dart';` no topo, porque o
    `flutter_test` não o reexporta;
  - os passos das etapas 1, 3 e 4 não mudaram.
- **Enquanto isso:** no merge, manter o import e o bloco da etapa 2 da
  V2-A junto com as etapas 1, 3 e 4 da V2-B.
