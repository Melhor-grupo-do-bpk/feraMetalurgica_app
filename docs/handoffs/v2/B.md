# Handoff V2-B

Pedidos e dúvidas da trilha V2-B ([`tarefas/v2/B-cliente-valores-previa.md`](../../tarefas/v2/B-cliente-valores-previa.md)).
Editado só pela própria trilha, na branch `feat/v2-b-cliente-valores`. Formato e regras em
[`orquestracao.md` §6](../../orquestracao.md#6-handoffs); as respostas do
orquestrador ficam em [`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

## Pedidos

### HO-V2-B-01: `CampoDinheiro` no `core/widgets/`
- **Tipo:** mudança em compartilhado (combinado com o responsável em
  30/10/2026)
- **Arquivo(s):** `lib/core/widgets/campo_dinheiro.dart` (novo);
  `lib/features/orcamentos/presentation/wizard/etapa_valores.dart`.
- **O quê:** juntar o `_CampoDinheiro` privado da etapa 3 e o campo igual
  da V2-A num `CampoDinheiro` público, com a interface
  `({String rotulo, Dinheiro? valorInicial, ValueChanged<Dinheiro?>
  onChanged, String? errorText})`. O da V2-B:
  - lê com `Dinheiro.tryParse` e teclado
    `TextInputType.numberWithOptions(decimal: true)`, aceitando só
    `0-9 . ,`;
  - `onChanged(null)` com o campo vazio; texto inválido **não** chama
    `onChanged` e mostra "Valor inválido: use até 2 casas (ex:
    1.234,56)" pelo `validator` (o `Form` em volta não valida);
  - `errorText` é o erro de regra vindo do controller;
  - o prefixo "R$" usa `textSecondary`: com a cor padrão do tema (dica)
    o contraste dava 4,05:1.
- **Por quê:** o `CurrencyField` do core usa `double`, o que a D-26 não
  permite.
- **Enquanto isso:** campo privado em `etapa_valores.dart`, com essa
  interface. Ao integrar, basta trocar `_CampoDinheiro` por
  `CampoDinheiro` (a etapa trata `null` como zero).

### HO-V2-B-02: linhas para o `telas_pequenas_test.dart`
- **Tipo:** mudança em compartilhado
- **Arquivo(s):** `test/widget/telas_pequenas_test.dart`
- **O quê:** a lista `sobreposicoes` ganha os estados da V2-B que não
  aparecem só navegando pelas rotas (o diálogo de descarte, a busca com
  resultados e o aviso de documento):

  ```dart
  (
    'diálogo "Descartar orçamento?"',
    AppRoutes.novoOrcamento(),
    () => [find.byTooltip('Voltar')],
  ),
  (
    'diálogo "Descartar alterações?"',
    AppRoutes.editarOrcamento(_c),
    () => [find.byTooltip('Voltar')],
  ),
  ```

  E um teste novo, ao lado do "etapas do wizard em 360 dp", com a busca
  aberta e o aviso de outro cadastro na etapa 1 (a busca e o documento são
  digitados, por isso não cabem em `sobreposicoes`):

  ```dart
  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapa 1 com busca e aviso em 360 dp, ${tema.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await abrir(
        tester,
        AppRoutes.editarOrcamento(_c),
        tamanho: tamanhos['360 dp']!,
        tema: tema,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('cliente-documento')),
          matching: find.byType(EditableText),
        ),
        '11.222.333/0001-81',
      );
      await tester.enterText(
        find.byKey(const ValueKey('wizard-busca-cliente')),
        'Silva',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cliente-aviso-outro-cadastro')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  }
  ```

  Confira o tooltip da seta da `AppTopBar` ("Voltar", o mesmo que o
  `wizard_fluxo_completo_test` usa nos detalhes).
- **Por quê:** orquestracao §3, pontos de contato.
- **Enquanto isso:** os mesmos casos rodam a 360 dp, claro e escuro, com
  contraste e área de toque, nos testes da trilha
  (`etapa_cliente_test`, `etapa_valores_test`, `etapa_previa_test` e
  `orcamento_wizard_page_test`). O teste "etapas do wizard em 360 dp"
  atual continua passando sem mudança.

### HO-V2-B-03: exportar a `PreviaOrcamento` para o PDF e os detalhes
- **Tipo:** contrato (barrel)
- **Arquivo(s):** `lib/features/orcamentos/orcamentos.dart`
- **O quê:** exportar
  `presentation/wizard/previa/previa_orcamento.dart` (e, se a V2-D quiser
  as linhas de total, `previa/linha_valor.dart` e
  `previa/aviso_total_zero.dart`). Contrato:
  - `PreviaOrcamento.deOrcamento(Orcamento, {bool mostrarPecas = false})`:
    os totais gravados, sem recalcular, e o `codigoExibicao`;
  - `PreviaOrcamento.daEdicao(OrcamentoEmEdicao, {required
    ResultadoOrcamento resumo, required DateTime agora, bool mostrarPecas
    = false})`: código com a próxima revisão na edição, "Número gerado ao
    finalizar" num novo;
  - o construtor padrão recebe os campos soltos;
  - sem providers nem calculadora; ordem da D-39; o PDF usa
    `mostrarPecas: false`.
- **Por quê:** prompt §4 (a prévia serve ao PDF depois). Hoje o barrel
  não exporta nada de `wizard/previa/`, e a V2-D não pode importar o
  arquivo interno.
- **Enquanto isso:** só a etapa 4 usa o widget.

### HO-V2-B-04: avisos para a integração
- **Tipo:** aviso
- **O quê:**
  - **Etapa 2 (V2-A):** a página concentra a passagem de etapa em
    `Future<bool> _podeSairDaEtapa(int etapa)`
    (`orcamento_wizard_page.dart`), chamado por "Continuar", "Voltar", a
    seta da barra do topo e o voltar do sistema (nas etapas 2 a 4; na
    etapa 1 o voltar pede o descarte). O `default` (etapa 2) devolve
    `true`: é ali que entra o `podeSairDaEtapaProdutos(context, ref)`. As
    etapas 1 e 3 ficam dentro de um `Form` próprio; a 2, não.
  - **Rodapé do wizard:** passou do corpo para o `bottomNavigationBar` do
    `Scaffold`, para o SnackBar aparecer acima dos botões. Antes ele
    cobria o "Continuar" por 4 s e engolia o toque seguinte. O `Align`
    do botão principal usa `heightFactor: 1`.
  - **`preencherStub`:** só mudaram os passos da etapa 1 (agora digita na
    busca `wizard-busca-cliente` e toca no resultado dentro de
    `wizard-resultados-cliente`); a linha do produto e os passos das
    etapas 3 e 4 ficaram iguais. A busca só lista clientes com o termo
    preenchido.
  - **Helper de teste duplicado:** `etapa_cliente_test`,
    `etapa_valores_test` e `orcamento_wizard_page_test` têm cada um o seu
    `abrir` (router mínimo com lista e detalhes em texto), porque helpers
    novos ficam no próprio arquivo da trilha. Sugestão para a V2-G: um
    `abrirWizard` em `wizard_teste_helpers.dart`.
  - **Contraste em diálogos (core):** o `TextButton` padrão do tema
    (`primary` sobre o fundo do `AlertDialog`) dá 4,41:1 no claro. O
    `confirmarAcao` usa `textPrimary` no "Cancelar" e `error` na ação
    destrutiva. Outros diálogos com o botão padrão vão falhar no
    `textContrastGuideline` se forem testados; vale corrigir no
    `AppTheme`.
  - **`ListTile` dentro do `SectionCard`:** o card não é um `Material`, e
    o `ListTile` reclama ("ink splashes may be invisible"). Os resultados
    da busca ficam num `Material(type: MaterialType.transparency)`.
