# Requisitos

Os requisitos foram extraídos das telas em [`../Teste/`](../Teste/) e já
ajustados pelas decisões de [`02-decisoes.md`](02-decisoes.md). Cada
requisito tem um ID (RF-xx) que as tarefas citam. Onde a tela e este arquivo
divergem, vale este arquivo.

## Navegação geral

- **RF-01**: Navegação inferior com 4 abas: Início, Orçamentos, Catálogo e
  Mais. Cada aba mantém sua pilha de navegação (já implementado pelo
  `StatefulShellRoute`).
- **RF-02**: Todas as telas usam `AppTopBar`. O botão voltar aparece em
  qualquer tela que não seja raiz de aba.
- **RF-03**: O wizard, os detalhes do orçamento, a prévia do PDF e o
  formulário de tarefa abrem em tela cheia, sem a navegação inferior
  ([D-11](02-decisoes.md#d-11)).

## Tela 1: Dashboard (aba Início)

- **RF-10**: Botão "Criar orçamento" que abre o wizard.
- **RF-11**: 4 indicadores ([D-03](02-decisoes.md#d-03)): Orçamentos em
  andamento, Aguardando aprovação, Aprovados e Pedidos em produção.
  Orçamentos em rascunho nunca contam.
- **RF-12**: "Orçamentos Recentes" mostra os 2 orçamentos mais recentes
  (excluindo rascunhos), com número, data, cliente, valor total e chip de
  status. O cartão abre os detalhes.
- **RF-13**: "Ver todos" leva à aba Orçamentos.
- **RF-14**: Os números atualizam sem reiniciar o app depois de criar ou
  editar um orçamento ou uma tarefa.

## Telas 2 a 5: Wizard de novo orçamento

- **RF-20**: 4 etapas com `StepProgressBar` e o título "Etapa N de 4: …".
  "Voltar" volta uma etapa e mantém o que já foi digitado. O voltar do
  sistema faz o mesmo. Sair do wizard na etapa 1 com dados preenchidos pede
  confirmação de descarte ([D-07](02-decisoes.md#d-07)).
- **RF-21 (etapa 1, cliente)**: Nome\*, Número\* (máscara de telefone),
  CPF/CNPJ\* (máscara que alterna conforme o tamanho e valida os dígitos
  verificadores), E-mail (validado se preenchido) e Observações.
  "Continuar" só avança se tudo for válido.
- **RF-22 (etapa 2, itens)**: Campo "Nome do projeto"
  ([D-02](02-decisoes.md#d-02)). Formulário de item com Tipo do serviço\*
  (lista de seleção vinda do catálogo + "Outro", [D-20](02-decisoes.md#d-20)),
  Medidas A/L/C em metros, Material principal, Especificações e Quantidade
  (padrão 1). Botões "Adicionar Item", editar e excluir item (`ItemCard`).
  "Continuar" exige pelo menos 1 item.
- **RF-23 (etapa 3, custos)**: 5 `CurrencyField` (Matéria-prima, Mão de
  obra, Insumos, Combustível, Impostos) e o card "Resumo de Custos" com o
  total previsto, atualizado enquanto se digita (`calcularTotalCustos`).
- **RF-24 (etapa 4, resumo)**: Cliente, Projeto, Itens do pedido (tipo,
  especificações, quantidade), Prazo estimado (`prazoDiasUteis` dias úteis,
  "Após aprovação e sinal."), Valor final (`Orcamento.valorFinal`) e o aviso
  "Visão do Cliente". "Continuar" grava o orçamento e abre os detalhes,
  substituindo o wizard na pilha.
- **RF-25**: Um orçamento novo é gravado com status `emAnalise` e o próximo
  número sequencial ([D-09](02-decisoes.md#d-09)).
- **RF-26**: Editar um orçamento reabre o wizard preenchido. Ao concluir,
  ele mantém `id`, `criadoEm` e `status`.
- **RF-27**: Entrar pelo catálogo (`?produtoId=`) já cria o primeiro item
  com aquele produto.

## Tela 6: Detalhes do orçamento

- **RF-30**: Cabeçalho com nome do cliente, "Cliente PF" ou "Cliente PJ"
  ([D-23](02-decisoes.md#d-23)), número do orçamento, data, prazo e
  validade ([D-04](02-decisoes.md#d-04)).
- **RF-31**: "Itens do Orçamento" de forma descritiva: tipo, medidas,
  material, especificações e "Qtd: N un". **Sem valor por item**
  ([D-01](02-decisoes.md#d-01)).
- **RF-32**: Card escuro "Valor Final" com os botões Enviar WhatsApp, Gerar
  PDF e Editar.
- **RF-33**: Botão de menu (⋮) no card do cliente com "Alterar status"
  ([D-06](02-decisoes.md#d-06)).
- **RF-34**: Enviar WhatsApp abre a conversa com o número do cliente e uma
  mensagem de resumo ([D-15](02-decisoes.md#d-15)). Depois disso, se o
  status era `emAnalise`, ele passa para `enviado`.

## Tela 7: Prévia do PDF

- **RF-40**: Pré-visualização do PDF do orçamento com logo, "ORÇAMENTO
  Nº 00482", data e validade; bloco EMISSOR (constantes,
  [D-04](02-decisoes.md#d-04)); bloco CLIENTE (nome, CPF/CNPJ, telefone,
  e-mail); tabela "Descrição do item / serviço | Qtd"; e uma linha
  "Valor Total".
- **RF-41**: O PDF nunca mostra custos internos ([D-16](02-decisoes.md#d-16)).
- **RF-42**: "Baixar" abre o compartilhamento do sistema com o arquivo
  `orcamento-00482.pdf`.

## Tela 8: Lista de orçamentos (aba Orçamentos)

- **RF-50**: Título "Orçamentos" e botão "Novo", que abre o wizard.
- **RF-51**: Busca por nome do cliente (sem diferenciar maiúsculas nem
  acentos) ou por número.
- **RF-52**: Chips de filtro: Todos, Rascunhos, Em análise, Enviados,
  Aprovados e Recusados ([D-22](02-decisoes.md#d-22)).
- **RF-53**: Cartão com número, cliente, chip de status, data e valor.
  Rascunho mostra "Valor Estimado" e os demais "Valor Total". O cartão abre
  os detalhes.
- **RF-54**: Ordenação pela data de criação, do mais recente ao mais antigo.
  Lista vazia mostra um estado vazio com o botão "Novo".

## Tela 9: Catálogo de produtos (aba Catálogo)

- **RF-60**: Título, subtítulo e chips de categoria ("Todos" + categorias
  distintas dos produtos).
- **RF-61**: Cartão com foto, nome, etiqueta da categoria e descrição técnica
  ([D-18](02-decisoes.md#d-18)).
- **RF-62**: Tocar no cartão abre uma folha (bottom sheet) com os detalhes e
  o botão "Usar no orçamento", que vai para `/orcamentos/novo?produtoId=<id>`.

## Aba Mais

- **RF-70**: Menu em lista com "Cronograma". Itens futuros entram aqui
  ([D-13](02-decisoes.md#d-13)).

## Tela 10: Cronograma e agenda

- **RF-80**: Calendário do mês com navegação ‹ ›, dia selecionado em
  destaque e ponto nos dias que têm tarefas pendentes.
- **RF-81**: "Filtros de tarefas" com 3 caixas de seleção, Orçamentos,
  Produção e Visitas, todas marcadas por padrão ([D-05](02-decisoes.md#d-05)).
- **RF-82**: Atalhos horizontais de dia ("Hoje, 9 Out", "Amanhã, 10 Out",
  "Qua, 11 Out"…) que mudam o dia selecionado.
- **RF-83**: Linha do tempo agrupada por dia (dia selecionado e o seguinte)
  com "N tarefas". Cada tarefa mostra hora, título, etiqueta do tipo e
  descrição.
- **RF-84**: Tocar no círculo da tarefa alterna `concluida`. Tarefa
  concluída aparece riscada e esmaecida.
- **RF-85**: "Ver Detalhes" aparece quando a tarefa tem `orcamentoId` e
  abre o orçamento.
- **RF-86**: O botão flutuante "+" abre o formulário de nova tarefa com
  título\*, data\*, hora\*, tipo\*, descrição e orçamento vinculado
  (opcional). Tocar e segurar uma tarefa abre a edição, com opção de excluir.

## Requisitos não funcionais

- **RNF-01**: Android e iOS, retrato. Modo claro e escuro (`context.colors`).
- **RNF-02**: Funciona offline. Persistência apenas via repositórios
  (`LocalJsonStorage`).
- **RNF-03**: `flutter analyze --fatal-infos` limpo e `flutter test` verde
  em todo PR (CI).
- **RNF-04**: Textos, datas e moeda em pt-BR (`formatarMoeda`, `DateFormat`
  com locale `pt_BR`).
- **RNF-05**: Toda tela trata os estados carregando, vazio e erro do
  `AsyncValue`.
- **RNF-06**: Áreas de toque de no mínimo 48 dp. Ícones de ação com
  `tooltip`/`semanticLabel`.
