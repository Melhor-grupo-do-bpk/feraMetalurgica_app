---
trilha: T6
titulo: Catálogo
status: pendente        # pendente | em andamento | em revisão | concluída
responsavel: —
branch: feat/t6-catalogo
depende_de: F1
---

# T6: Catálogo de produtos (Tela 9)

**Requisitos:** RF-60 a RF-62.
**Decisões:** D-18, D-20.
**Arquivos:** `catalogo/presentation/**` (exceto `catalogo_controller.dart`,
`catalogo_routes.dart` e `catalogo_ui.dart`), `assets/images/catalogo/**` e
`test/widget/catalogo/**`.

## Checklist
- [ ] `CatalogoPage`: `AppTopBar` sem voltar, título "Catálogo de
      Produtos", subtítulo do Figma, e `FilterChipsBar` com "Todos" +
      categorias (D-18).
- [ ] Provider da tela com a categoria selecionada e a lista filtrada a
      partir de `produtosCatalogoProvider`.
- [ ] Cartão do produto: foto 16:9 (asset, arquivo ou placeholder, D-18),
      nome, etiqueta da categoria e descrição técnica.
- [ ] Toque abre um bottom sheet com foto, nome, categoria, descrição e
      `PrimaryButton` "Usar no orçamento", que fecha o sheet e faz
      `context.push(AppRoutes.novoOrcamento(produtoId: id))`.
- [ ] Fotos dos 3 produtos do seed em `assets/images/catalogo/<id>.jpg`
      (imagens livres de direitos, no máximo ~200 KB cada). A F1 já aponta
      os `fotoPath` do seed para esses caminhos.
- [ ] Estados carregando, vazio e erro.

## Testes
- [ ] Widget: renderiza os 3 produtos do seed, o filtro por categoria reduz a
      lista, e "Usar no orçamento" navega com o `produtoId`.

## Critério de aceite
Igual à Tela 9. "Usar no orçamento" abre o wizard (após a T3, já com o item
preenchido).
