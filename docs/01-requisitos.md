# Requisitos

Requisitos da rodada v2: orçamento por produtos e peças, cadastros de
materiais e da empresa, remoção do catálogo e a Agenda como aba. Partem das
telas em [`../Teste/`](../Teste/), do
[`prompt-modulo-orcamento-v2.md`](prompt-modulo-orcamento-v2.md) e das
decisões de [`02-decisoes.md`](02-decisoes.md) (D-26 a D-41 valem sobre o
prompt). Cada requisito tem um ID (RF-xx) que as tarefas citam. Onde a tela
e este arquivo divergem, vale este arquivo.

Os IDs da rodada telas-v1 que continuam com o mesmo sentido foram mantidos.
Os que saíram ficam listados no fim, para as tarefas antigas
(`docs/tarefas/T*.md`), que são histórico.

## Navegação geral

- **RF-01**: Navegação inferior com 4 abas: Início, Orçamentos, Agenda e
  Mais ([D-31](02-decisoes.md#d-31)). Cada aba mantém sua pilha de
  navegação (`StatefulShellRoute`).
- **RF-02**: Todas as telas usam `AppTopBar`. O botão voltar aparece em
  qualquer tela que não seja raiz de aba.
- **RF-03**: O wizard, os detalhes do orçamento, a prévia do PDF, o
  formulário de tarefa e os formulários de cadastro abrem em tela cheia,
  sem a navegação inferior ([D-11](02-decisoes.md#d-11)).

## Tela 1: Dashboard (aba Início)

- **RF-10**: Botão "Criar orçamento" que abre o wizard. Sem os dados da
  empresa completos, leva a "Dados da empresa" ([D-38](02-decisoes.md#d-38)).
- **RF-11**: 4 indicadores ([D-32](02-decisoes.md#d-32)): Criados, Enviados
  no mês (por `enviadoEm`, [D-37](02-decisoes.md#d-37)), Valor enviado no
  mês (soma do total geral desses orçamentos) e Pedidos em produção
  (tarefas de produção pendentes).
- **RF-12**: "Orçamentos Recentes" mostra os 2 orçamentos de `atualizadoEm`
  mais recente, com código (e "rev. N"), data, cliente, total geral e chip
  de status. O cartão abre os detalhes.
- **RF-13**: "Ver todos" leva à aba Orçamentos.
- **RF-14**: Os números atualizam sem reiniciar o app depois de criar,
  editar, enviar ou excluir um orçamento ou uma tarefa.

## Telas 2 a 5: Wizard de orçamento

O estado da edição fica no `OrcamentoController` ([D-28](02-decisoes.md#d-28)),
só em memória. O valor final nunca é digitado: é sempre o
`ResultadoOrcamento` da `CalculadoraOrcamento` (prompt §5,
[D-26](02-decisoes.md#d-26)).

- **RF-20**: 4 etapas com `StepProgressBar` e o título "Etapa N de 4: …".
  "Voltar", a seta do topo e o voltar do sistema voltam uma etapa e mantêm
  o que já foi digitado. Sair do wizard pede confirmação de descarte
  ("Descartar orçamento?" num novo, "Descartar alterações?" na edição).
- **RF-21 (etapa 1, cliente)**: Busca de clientes cadastrados por nome,
  celular ou documento. Escolher um preenche uma cópia editável. Nome,
  documento (CPF ou CNPJ, com os dígitos verificadores), celular e
  endereço (logradouro, número, bairro, cidade, UF; CEP e complemento
  opcionais) são obrigatórios ([D-34](02-decisoes.md#d-34)). Um documento
  de outro cadastro avisa e oferece "Usar cadastro"; o cadastro só é
  criado ou atualizado ao finalizar.
- **RF-22 (etapa 2, produtos e peças)**: Lista de produtos com descrição,
  quantidade, preço base e total, e as ações editar, duplicar (cópia com
  ids novos) e remover. O formulário do produto tem descrição, quantidade
  (≥ 1), "Preço base de fabricação por produto (sem materiais)" e as
  peças. Cada peça tem descrição, material (só os ativos, com o atalho
  "Cadastrar material"), preço aplicado (copiado do cadastro e editável
  só na peça, com aviso de ajuste), comprimento, largura, espessura
  (obrigatória em m³) e quantidade por produto. O resumo ao vivo mostra o
  consumo e o custo de cada peça e o preço unitário do produto. Avançar ou
  voltar com um produto em montagem pede confirmação. "Continuar" exige
  pelo menos 1 produto.
- **RF-23 (etapa 3, valores)**: Insumos, impostos, combustível, outros
  (com descrição obrigatória se maior que zero), desconto (não pode passar
  do subtotal), validade em dias corridos (opcional) e observações, com o
  campo `CampoDinheiro` ([D-26](02-decisoes.md#d-26)). O resumo mostra o
  total dos produtos, os adicionais, o subtotal, o desconto e o total
  geral, que não é editável. Total zero é permitido e aparece destacado.
- **RF-24 (etapa 4, prévia)**: A `PreviaOrcamento`, na ordem da
  [D-39](02-decisoes.md#d-39): cliente e emitente, produtos com
  quantidade, preço unitário e total, total dos produtos, cada adicional
  maior que zero, subtotal, desconto e total geral. Num novo, o código
  aparece como "Número gerado ao finalizar"; na edição, com a próxima
  revisão.
- **RF-25**: "Finalizar" grava o orçamento pelo `FinalizarOrcamentoService`
  numa transação, com status `criado` e o código `DDMMAA-NN` do dia
  ([D-30](02-decisoes.md#d-30)). O botão bloqueia o clique duplo e mostra o
  progresso; a `chaveFinalizacao` impede gravar duas vezes. Se falhar, os
  dados ficam e dá para tentar de novo. Se der certo, abre os detalhes no
  lugar do wizard.
- **RF-26**: "Editar" reabre o wizard com uma cópia do orçamento. "Salvar
  alterações" grava no lugar a `revisao + 1`, com `atualizadoEm` novo,
  totais recalculados e cliente e empresa copiados de novo; um orçamento
  `enviado` volta para `criado` ([D-30](02-decisoes.md#d-30),
  [D-37](02-decisoes.md#d-37)).

## Tela 6: Detalhes do orçamento

- **RF-30**: Cabeçalho com o código (`281026-03`, ou `281026-03 rev. 2`
  a partir da 2ª revisão), o chip de status, o cliente e o emitente das
  cópias gravadas.
- **RF-31**: A `PreviaOrcamento` com os **totais gravados**, sem
  recalcular. O interruptor "Mostrar peças e custos", desligado por
  padrão, mostra o detalhe interno das peças. Validade e observações
  aparecem quando existem.
- **RF-32**: Ações: Enviar WhatsApp, Gerar PDF e Editar.
- **RF-33**: Menu (⋮) com "Marcar como enviado" (direto) ou "Voltar para
  criado" (com confirmação, porque apaga o `enviadoEm`), e "Excluir" (com
  confirmação). Excluir não libera o código e tira o vínculo das tarefas
  ([D-29](02-decisoes.md#d-29), [D-37](02-decisoes.md#d-37)).
- **RF-34**: Enviar WhatsApp abre a conversa com o celular do cliente e uma
  mensagem com o código, a revisão, o total geral e a validade, se houver
  ([D-15](02-decisoes.md#d-15), [D-39](02-decisoes.md#d-39)). Se abrir, o
  status passa a `enviado` e o `enviadoEm` recebe a data, sem mudar o
  `atualizadoEm`; reenviar mantém a data do primeiro envio.
- **RF-35**: Seção "Agenda" com as tarefas do orçamento (pendentes
  primeiro, depois as concluídas, em ordem cronológica; sem tarefas,
  "Nenhuma tarefa agendada.") e o botão "Agendar", que abre uma tarefa nova
  de Produção vinculada, com o título "Produção <código>"
  ([D-41](02-decisoes.md#d-41)).

## Tela 7: Prévia do PDF

- **RF-40**: PDF com logo, "Nº 281026-03" (e "rev. N"), data, validade (só
  se houver), emitente e cliente das cópias, produtos com quantidade, preço
  unitário e total, e os totais na ordem da [D-39](02-decisoes.md#d-39).
- **RF-41**: O PDF nunca mostra o custo das peças e dos materiais
  ([D-39](02-decisoes.md#d-39)).
- **RF-42**: "Baixar" abre o compartilhamento do sistema com o arquivo
  `orcamento-<código>.pdf`.

## Tela 8: Lista de orçamentos (aba Orçamentos)

- **RF-50**: Título "Orçamentos" e botão "Novo", que abre o wizard (com a
  mesma exigência da empresa do RF-10).
- **RF-51**: Busca por nome do cliente (sem diferenciar maiúsculas nem
  acentos) ou por código.
- **RF-52**: Chips de filtro: Todos, Criados e Enviados
  ([D-29](02-decisoes.md#d-29)).
- **RF-53**: Cartão com código (e "rev. N"), cliente, chip de status, data
  de `atualizadoEm` e total geral. O cartão abre os detalhes.
- **RF-54**: Ordenação por `atualizadoEm`, do mais recente ao mais antigo.
  Lista vazia mostra um estado vazio com o botão "Novo".

## Aba Mais

- **RF-70**: Menu em lista com "Materiais" e "Dados da empresa"
  ([D-13](02-decisoes.md#d-13), [D-31](02-decisoes.md#d-31)).

## Materiais (Mais → Materiais)

- **RF-90**: Lista com busca, mostrando nome, unidade (m² ou m³), preço de
  referência e situação, com o filtro Ativos/Todos.
- **RF-91**: Novo e editar: nome, unidade e preço de referência (maior que
  zero). Salvar volta à tela anterior com o id do material, o que serve ao
  atalho "Cadastrar material" da etapa 2.
- **RF-92**: Inativar (com confirmação) e reativar. Material não é
  excluído; o inativo some das novas seleções, e os orçamentos salvos não
  mudam, porque guardam a cópia ([D-26](02-decisoes.md#d-26)).
- **RF-93**: Num material já usado em orçamento salvo, a unidade não muda:
  o formulário orienta a cadastrar um material novo e inativar o atual
  ([D-40](02-decisoes.md#d-40)).

## Dados da empresa (Mais → Dados da empresa)

- **RF-95**: Nome ou razão social, CPF/CNPJ, telefone e endereço
  obrigatórios, e-mail opcional. É o emitente dos orçamentos novos e das
  edições (copiado ao finalizar). Uma empresa só.
- **RF-96**: Sem a empresa completa, "Novo orçamento" e "Editar" levam a
  esta tela, com a orientação para liberar o orçamento
  ([D-38](02-decisoes.md#d-38)).

## Tela 10: Agenda (aba Agenda)

- **RF-80**: Calendário do mês com navegação ‹ ›, dia selecionado em
  destaque e ponto nos dias que têm tarefas pendentes.
- **RF-81**: "Filtros de tarefas" com 3 caixas de seleção, Orçamentos,
  Produção e Visitas, todas marcadas por padrão ([D-05](02-decisoes.md#d-05)).
- **RF-82**: Atalhos horizontais de dia ("Hoje, 9 Out", "Amanhã, 10 Out",
  "Qua, 11 Out"…) que mudam o dia selecionado.
- **RF-83**: Linha do tempo agrupada por dia (dia selecionado e o seguinte)
  com "N tarefas". Cada tarefa mostra hora, título, etiqueta do tipo e
  descrição. Em telas estreitas, a etiqueta fica acima do título.
- **RF-84**: Tocar no círculo da tarefa alterna `concluida`. Tarefa
  concluída aparece riscada e esmaecida.
- **RF-85**: "Ver Detalhes" aparece quando a tarefa tem `orcamentoId` e
  abre o orçamento.
- **RF-86**: O botão flutuante "+" abre o formulário de nova tarefa com
  título\*, data\*, hora\*, tipo\*, descrição e orçamento vinculado
  (opcional). Tocar e segurar uma tarefa abre a edição, com opção de
  excluir (com confirmação).
- **RF-87**: Tarefa atrasada é a pendente de um dia anterior ao de hoje.
  Um aviso no topo da agenda conta todas, apesar dos filtros, e "Ver" abre
  a lista delas; tocar numa leva ao dia dela. Na agenda e nas tarefas do
  orçamento, a atrasada tem faixa e marcador na cor de erro e a etiqueta
  "ATRASADA" ([D-41](02-decisoes.md#d-41)).

## Requisitos não funcionais

- **RNF-01**: Android e iOS (e Windows, para desenvolvimento), retrato.
  Modo claro e escuro (`context.colors`). Telas conferidas a 360 dp,
  412 dp e tablet (`telas_pequenas_test`).
- **RNF-02**: Funciona offline. Persistência só pelos repositórios, num
  banco SQLite local, com gravações de vários registros em transação
  ([D-27](02-decisoes.md#d-27)).
- **RNF-03**: `flutter analyze --fatal-infos` limpo e `flutter test` verde
  em todo PR (CI).
- **RNF-04**: Textos, datas e moeda em pt-BR (`Dinheiro.formatado`,
  `DateFormat` com locale `pt_BR`).
- **RNF-05**: Toda tela trata os estados carregando, vazio e erro do
  `AsyncValue`.
- **RNF-06**: Áreas de toque de no mínimo 48 dp. Ícones de ação com
  `tooltip`/`semanticLabel`. Contraste mínimo de 4,5:1
  ([D-25](02-decisoes.md#d-25)).
- **RNF-07**: Nunca `double` em dinheiro, medida ou consumo
  ([D-26](02-decisoes.md#d-26)).

## Requisitos da rodada telas-v1 que saíram

| ID | Era | Por quê |
|---|---|---|
| RF-27 | Entrar pelo catálogo com `?produtoId=` | Catálogo removido (D-31) |
| RF-60 a RF-62 | Catálogo de produtos (Tela 9) | Catálogo removido (D-31) |
| RF-23 (v1) | Etapa 3 com 5 `CurrencyField` de custos e margem | Preço base, adicionais e desconto (D-26); o `CurrencyField` saiu por usar `double` |
| RF-11 (v1) | Indicadores por status de 5 valores | Status `criado` e `enviado` (D-29, D-32) |
