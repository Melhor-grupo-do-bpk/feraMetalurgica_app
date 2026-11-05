# Handoff V2-C

Pedidos e dúvidas da trilha V2-C ([`tarefas/v2/C-cadastros.md`](../../tarefas/v2/C-cadastros.md)).
Editado só pela própria trilha, na branch `feat/v2-c-cadastros`. Formato e regras em
[`orquestracao.md` §6](../../orquestracao.md#6-handoffs); as respostas do
orquestrador ficam em [`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

Caminhos relativos a `fera_metalurgica_app/`.

## Pedidos

### HO-V2-C-01: linhas para o `telas_pequenas_test.dart`
- **Tipo:** mudança em compartilhado
- **Arquivo(s):** `test/widget/telas_pequenas_test.dart`
- **O quê:**
  1. Na lista `rotas`, logo depois de `AppRoutes.material()`, a edição de
     um material em uso:
     ```dart
     AppRoutes.material(id: 'material-granito'),
     ```
  2. Na lista `sobreposicoes`:
     ```dart
     (
       'diálogo "Inativar material?"',
       AppRoutes.materiais,
       () => [
         find.byTooltip('Ações do material MDF 15 mm'),
         find.text('Inativar'),
       ],
     ),
     (
       'diálogo "A unidade não pode mudar" (material em uso)',
       AppRoutes.material(id: 'material-granito'),
       () => [find.text('m³')],
     ),
     ```
- **Por quê:**
  - a edição muda conforme o material está ou não em uso (D-40). Nos dados
    de exemplo, o granito está nos orçamentos B e C, então o aviso
    aparece;
  - os dois diálogos só aparecem depois de um toque.
- **Enquanto isso:**
  - testei as linhas localmente, sem commitar: o arquivo inteiro passou
    (153 testes);
  - a trilha confere as próprias telas a 360 dp, no claro e no escuro, em
    `test/widget/materiais/*_test.dart` e
    `test/widget/empresa/empresa_page_test.dart`, com o contraste e as
    áreas de toque;
  - o formulário de material e a empresa com os erros visíveis **não**
    entraram nas linhas acima: o `tocar` da `wizard_teste_helpers.dart` só
    faz `ensureVisible`, e a 360 dp o botão "Salvar" ainda não foi montado
    pelo `ListView`. Os testes da trilha cobrem esses dois casos.

### HO-V2-C-02: avisos
- **Tipo:** aviso
- **O quê:**
  - **Contrato com a V2-A mantido (HO-V2-A-02):**
    - `context.push<String>(AppRoutes.material())` devolve o id ao salvar e
      `null` ao voltar sem salvar. Os dois casos têm teste em
      `material_form_page_test.dart`;
    - `UnidadeCobrancaUi.simbolo` não mudou. Entrou `descricao` ("metro
      quadrado", "metro cúbico"), usada no tooltip do seletor de unidade;
    - os nomes `MateriaisPage`, `MaterialFormPage` e `EmpresaPage` e os
      materiais de exemplo não mudaram.
  - **Novo no barrel de `materiais`** (pelo arquivo do formulário, que já
    era exportado): a constante `mensagemUnidadeEmUso`. Os arquivos novos
    de `lista/` (`materiais_lista_filtro.dart`, `material_card.dart` e
    `alternar_situacao_material.dart`) são internos e não precisam ir para
    o barrel.
  - **Para a V2-G:**
    - o diálogo "Inativar material?" repete o estilo do `confirmarAcao` da
      V2-B (`wizard/wizard_dialogos.dart`): "Cancelar" com `textPrimary` e
      a ação com `error` (D-25). A feature de materiais não pode importar o
      wizard. Se o `confirmarAcao` for para o `core/widgets/`, os dois
      diálogos podem usá-lo;
    - os helpers de teste da trilha
      (`test/widget/materiais/materiais_teste_helpers.dart`) também são
      usados pelo teste da empresa. O `tocar` e o `digitar` deles rolam o
      `ListView` até montar o alvo. Podem ir para `test/widget/core/` junto
      com o `tocar` da `wizard_teste_helpers.dart`, que não rola.
  - **Merge da integração:** a branch recebeu `integracao/v2` em
    `bdee6e6` (fast-forward), com autorização do responsável, antes do
    primeiro commit da trilha.
- **Enquanto isso:** nada a fazer.
