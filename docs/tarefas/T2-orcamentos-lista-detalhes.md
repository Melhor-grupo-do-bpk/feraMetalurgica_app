---
trilha: T2
titulo: Lista e detalhes de orçamentos
status: em revisão      # pendente | em andamento | em revisão | concluída
responsavel: agente T2 (Claude Code)
branch: feat/t2-orcamentos-lista-detalhes
depende_de: F1
---

# T2: Lista e detalhes de orçamentos (Telas 8 e 6)

**Requisitos:** RF-50 a RF-54, RF-30 a RF-33.
**Decisões:** D-01, D-06, D-22, D-23, D-04.
**Arquivos:** `orcamentos/presentation/lista/**`,
`orcamentos/presentation/detalhes/**`, `test/widget/orcamentos/lista/**` e
`test/widget/orcamentos/detalhes/**`.

## Checklist

### Lista (`OrcamentosListaPage`, Tela 8)
- [x] Cabeçalho "Orçamentos" + `DarkButton` "Novo", que abre
      `AppRoutes.novoOrcamento()`.
- [x] Campo de busca "Buscar por cliente ou número..." (sem diferenciar
      maiúsculas nem acentos; números comparados só pelos dígitos).
- [x] `FilterChipsBar` com os chips de D-22.
- [x] Provider da tela (`OrcamentosListaFiltro`) com busca + status, e um
      provider derivado com a lista filtrada a partir de `orcamentosProvider`.
- [x] Cartão (Tela 8): `#id`, cliente, `StatusChip`, data e "Valor Total"
      (ou "Valor Estimado" em rascunho). Tocar abre os detalhes.
- [x] Estados carregando, vazio ("Nenhum orçamento encontrado") e erro.

### Detalhes (`OrcamentoDetalhesPage`, Tela 6)
- [x] Lê `orcamentoPorIdProvider(id)`. Se o id não existir, mostra "Orçamento
      não encontrado" com voltar.
- [x] Card do cliente: nome, "Cliente PF/PJ", `#id`, data, prazo ("15 dias
      úteis") e validade ("15 dias"), mais o menu ⋮ "Alterar status" (D-06),
      que salva via `orcamentosProvider.notifier.salvar`.
- [x] "Itens do Orçamento" descritivos (D-01): sem preço.
- [x] Card escuro "Valor Final" com 3 botões. **Editar** abre
      `AppRoutes.editarOrcamento(id)`. **Gerar PDF** abre
      `AppRoutes.pdfOrcamento(id)`. **Enviar WhatsApp** fica com
      `onPressed` chamando um método `_enviarWhatsApp` vazio, com
      `// TODO(T5)`: a T5 implementa.

### Testes
- [x] Lista: renderiza o seed, filtra por status, busca por nome e por
      número, mostra o estado vazio, e o toque navega.
- [x] Detalhes: renderiza o seed #00482, não mostra custos internos, e a
      troca de status chama `salvar`.

## Critério de aceite
Telas 8 e 6 iguais ao Figma, exceto pelo que as decisões mudaram (preço por
item e menu de status), em modo claro e escuro.
