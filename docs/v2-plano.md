# FERA v2: inventário, lacunas e plano

28/10/2026 · resposta às etapas 1 a 4 da seção 11 de
[`prompt-modulo-orcamento-v2.md`](prompt-modulo-orcamento-v2.md).
Nenhum código foi alterado. **Plano aprovado pelo responsável em
29/10/2026**, com todas as propostas abaixo (D-26 a D-32, opção principal
da D-30) e os itens 1, 2, 3, 4 e 7 da seção 6.

Escopo desta rodada:
- novo módulo de orçamento por peças (o prompt);
- remoção do catálogo;
- melhorias no agendamento (cronograma), a definir na seção 6.

## 1. Inventário do beta (telas v1, `main` em `5547d9d`)

| Área | Como está hoje |
|---|---|
| Modelos | `Orcamento` (`id` "00482" que é também o número, `cliente`, `projeto`, `itens`, `custosOperacionais`, `status`, `criadoEm`, `prazoDiasUteis`), `ItemOrcamento` descritivo (`tipoServico`, `Medidas` em metros `double`, `materialPrincipal` em texto, `quantidade`, `produtoId` do catálogo), `CustosOperacionais` (5 campos `double`), `Cliente` (`nome`, `numero`, `cpfCnpj`, `email?`, `observacoes?`, sem endereço). Não existem material, empresa nem peça. |
| Cálculo | `calculo_orcamento.dart`: `valorFinal = soma dos custos × (1 + 62,5%)`, tudo em `double`. Itens não têm valor (D-01). |
| Número | `proximoIdOrcamento` = maior id + 1: reutiliza o número depois de excluir o último. |
| Estado | Riverpod com codegen. `OrcamentosController` (lista, keepAlive) e `OrcamentoWizardController` (sessão do wizard em memória, D-21). |
| Persistência | `LocalJsonStorage`: um arquivo JSON por coleção (`orcamentos`, `catalogo`, `tarefas`). Sem transação, sem versão de esquema. |
| Rascunho | Não persistido (D-07); o enum ainda tem `rascunho`. |
| Telas | Wizard de 4 etapas (cliente, itens, custos, resumo), lista com busca e filtro por status, detalhes com "Alterar status", "Editar", PDF e WhatsApp. |
| Consumidores do orçamento | Dashboard (contagem por status, recentes, `valorFinal`), PDF (`orcamento_pdf_builder`), mensagem do WhatsApp (projeto, valor, prazo, validade), cronograma (`Tarefa.orcamentoId` e a lista de vínculo do formulário). |
| Emissor e validade | Constantes em `AppConstants` (D-04). |
| Catálogo | Feature completa: aba, repositório, seed, fotos em assets e "Usar no orçamento" (D-18, D-20). |
| Testes | 380 testes. Cerca de 120 tocam o modelo de orçamento (unitários de cálculo, JSON, controllers, PDF e WhatsApp; widgets do wizard, lista, detalhes, dashboard e telas pequenas). |
| Dados gravados | Só de teste: os exemplos de debug e o que foi criado no APK de teste. |

## 2. Análise de lacunas

| O que existe | O que o prompt exige | Ação |
|---|---|---|
| Item com um material em texto e medidas em metros | Produto com uma ou mais peças, cada peça com um material (snapshot) e medidas em cm | **Substituir** `ItemOrcamento` e `Medidas`; criar `PecaOrcamento` e `MaterialSnapshot` |
| `double` em dinheiro e medidas | Dinheiro em centavos inteiros; medidas decimais exatas | **Criar** `Dinheiro` (centavos `int`) e `MedidaCm` (centésimos de cm em `int`, cálculo intermediário em `BigInt`: exato, sem pacote novo) |
| Custos operacionais e margem de 62,5% | Preço base por produto, adicionais (insumos, impostos, combustível, outros), desconto; sem margem | **Substituir** `CustosOperacionais` e `calculo_orcamento.dart` pela `CalculadoraOrcamento`; a margem e a D-08 saem |
| Sem snapshots | Cópias de material, cliente e empresa no orçamento | **Criar** `MaterialSnapshot`, `ClienteSnapshot`, `EmpresaSnapshot` |
| Sem cadastro de material | Material com `ativo`, inativar em vez de excluir, preço editável só na peça | **Criar** feature de materiais (tela e repositório) |
| Emissor em constantes | Cadastro da empresa; sem ele não há "Novo orçamento" | **Criar** cadastro da empresa e **remover** as constantes do emissor |
| Cliente embutido no orçamento, sem endereço | Cadastro de clientes, documento normalizado como chave, endereço obrigatório | **Criar** `ClienteRepository` e busca; `Cliente` ganha `endereco` e perde `email` e `observacoes` |
| Número = maior id + 1 | Número que não se repete; gravação em transação; chave idempotente | **Substituir**: id `uuid`, contador persistido, `chaveFinalizacao` (ver D-30) |
| JSON por coleção | SQLite, tabelas, transação, unicidade e versão de esquema | **Substituir** por SQLite (D-27) |
| Rascunho no enum, não usado | Sem rascunho persistido | **Remover** `rascunho` (já não era gravado) |
| Status de 5 valores | (o prompt não trata) | **Substituir** por `criado` e `enviado` (D-29) |
| "Editar" sobrescreve o orçamento | Finalizado imutável, sem edição | **Ajustado pelo responsável**: edição continua (D-30) |
| Validade constante de 15 dias, prazo de 15 dias úteis | `validadeDias?` opcional por orçamento; sem prazo | **Substituir** a validade; **remover** o prazo (ver D-26) |
| Descarte ao sair já pede confirmação | Mantido | **Manter** |
| Wizard Riverpod | O prompt cita `ChangeNotifier` com Provider | **Manter Riverpod**, que é regra do projeto (D-28) |
| Catálogo | Fora do escopo | **Remover** (D-31) |

## 3. Migração de dados (decidida)

Os dados atuais são só de teste. O app novo **recria o armazenamento**: o
banco SQLite nasce vazio, sem migrar os arquivos JSON do beta. Os arquivos
antigos não são lidos nem apagados pelo app; ficam órfãos na pasta do
aplicativo e somem quando o app é reinstalado.

Os exemplos de debug (D-17) passam a ser os casos A e B da seção 9 do
prompt, mais um material de cada unidade e uma empresa de exemplo.

A partir daqui, toda mudança de esquema é uma migração versionada do SQLite
(`onUpgrade`).

## 4. Decisões

Entram em [`02-decisoes.md`](02-decisoes.md) na primeira tarefa da rodada.

- **D-26 Modelo por peças (decidida).** Vale o modelo da seção 7 do prompt,
  com estas diferenças:
  - edição e status, conforme D-29 e D-30;
  - Riverpod no lugar do Provider (D-28).

  Ficam obsoletas a D-01 (itens sem valor), a D-02 (nome do projeto), a
  D-04 (emissor e validade constantes), a D-08 (margem e prazo) e a D-20
  (tipo de serviço do catálogo). O campo `projeto` sai; o que ele dizia vai
  para a descrição do produto ou para as observações. O prazo de entrega
  sai, porque o prompt não o pede; se o cliente quiser, entra em
  observações.
- **D-27 SQLite (decidida).** Dependências novas:
  - `sqflite` no app;
  - `sqflite_common_ffi`, só nos testes e para rodar no Windows.

  Todos os dados vão para o SQLite, inclusive as tarefas do cronograma,
  para não manter dois mecanismos de persistência (regra 1 do
  `CLAUDE.md`). O `LocalJsonStorage` é removido quando o último uso sair.
- **D-28 Riverpod (decidida).** A regra 4 do
  `CLAUDE.md` proíbe Provider e `ChangeNotifier`. O `OrcamentoController`
  do prompt vira um Notifier Riverpod com as mesmas operações e o mesmo
  estado: edição, etapa, resumo, erros e `finalizando`.
- **D-29 Status `criado` e `enviado` (decidida).**
  - Ao finalizar, o orçamento fica `criado`.
  - Enviar pelo WhatsApp muda para `enviado`.
  - Nos detalhes, dá para alternar manualmente entre os dois.
  - O enum é serializado pelo nome.
  - A lista filtra por "Todos", "Criados" e "Enviados".
  - Os cards do dashboard são revistos no item 5.
- **D-30 Edição e controle de versões (decidida: código `AAMMDD-NN` e revisão).** A edição
  continua possível e o controle deixa de ser o número de série. Proposta:
  - **Identificação:** cada orçamento tem um **código** gerado ao criar, com
    data e sequência do dia: `AAMMDD-NN` (ex: `281026-03`, o terceiro do dia
    28/10/2026). Não se reutiliza, porque o contador do dia é persistido. Não
    depende de uma série global, e o código já diz quando o orçamento nasceu.
  - **Controle das alterações:** cada orçamento tem `revisao` (começa em 1)
    e `atualizadoEm`.
    - Editar e salvar grava uma nova revisão no lugar da anterior, com os
      totais recalculados e novos snapshots dos cadastros.
    - Se o orçamento estava `enviado`, volta para `criado`, porque o
      cliente tem uma versão desatualizada.
    - A lista, os detalhes, o PDF e o WhatsApp mostram "rev. 2".
  - **Histórico:** só a revisão atual é guardada. Guardar todas as revisões
    é possível depois, com uma tabela de revisões.

  Alternativas, se preferir:
  - (b) manter um número sequencial simples só como identificador
    amigável, mais a revisão;
  - (c) sem código: identificar pelo cliente e pela data.

  A edição reabre o wizard com o orçamento carregado. A `chaveFinalizacao`
  continua evitando gravar duas vezes no clique duplo.
- **D-31 Catálogo removido (decidida).** Sai a feature `catalogo` inteira:
  aba, rotas, seed, fotos, testes, D-18 e D-20, e o `produtoId` do item. A
  aba "Catálogo" é substituída pela **Agenda** (o cronograma, hoje dentro de
  "Mais"). Assim a navegação fica Início, Orçamentos, Agenda e Mais, e
  "Mais" passa a ter Materiais e Dados da empresa. **(decidida)**
- **D-32 Dashboard (decidida).** Os quatro cards passam a ser:
  - Criados: orçamentos que ainda não foram enviados;
  - Enviados no mês;
  - Valor enviado no mês: soma do total geral;
  - Pedidos em produção: tarefas de produção pendentes, como hoje.

  Os "recentes" continuam mostrando os 2 últimos orçamentos, criados ou
  enviados.

Pontos menores, que seguem o prompt salvo objeção:
- **Cliente:** `email` e `observacoes` saem; o celular continua sendo o
  número do WhatsApp.
- **Validade:** campo opcional na etapa 3 (`validadeDias`). Sem validade,
  o PDF e o WhatsApp não mostram a linha.
- **"Outros":** com valor maior que zero, exige descrição.
- **Total zero:** é permitido, mas aparece destacado para conferência.
  Isso responde o HO-T3-01.

## 5. Como executar

Mesmo modelo da rodada das telas ([`orquestracao.md`](orquestracao.md)).
Um agente por trilha, cada um em sua branch e worktree, a partir de uma
nova integração `integracao/v2`. O orquestrador revisa os planos, aplica os
handoffs, integra e roda as verificações. A `main` só recebe o resultado
por PR, com CI verde.

O prompt manda concluir modelo, cálculo, esquema e repositórios antes das
telas (seção 11.6). Por isso a rodada tem uma fundação sequencial e depois
trilhas paralelas.

| Trilha | Conteúdo | Depende de |
|---|---|---|
| **V2-F1 Domínio e cálculo** | Objetos de valor (`Dinheiro`, `MedidaCm`, `UnidadeCobranca`, `Documento`, `Endereco`), modelos freezed (cadastros, snapshots, composição, resultados), `CalculadoraOrcamento`, `ValidacaoService` e os testes de **todos** os cenários da seção 9. Só código puro, sem tela. Também atualiza o `CLAUDE.md`, o `.cursorrules` e o `02-decisoes.md` com o modelo novo. | — |
| **V2-F2 Persistência e adaptação** | SQLite (esquema v1, unicidade, ordem de itens e peças), repositórios de material, empresa, cliente, orçamento, sequência e tarefas, `UnidadeDeTrabalho`, serviço de finalização e edição, controller da edição (Notifier) e seeds. Troca o modelo antigo pelo novo em todo o app, com o mínimo nas telas para compilar: o wizard antigo vira um placeholder até a V2-A. Também remove o catálogo e reorganiza as abas. | F1 |
| **V2-A Wizard: produtos e peças** | Etapa 2 e a composição do produto: formulário da peça, resumo ao vivo, duplicar, editar, remover e avisos. | F2 |
| **V2-B Wizard: cliente, valores e prévia** | Etapa 1 (busca por nome, celular ou documento, cópia editável, aviso de troca de documento), etapa 3 (adicionais, desconto, validade, observações) e etapa 4 (prévia como widget separado), além do "Finalizar". | F2 |
| **V2-C Cadastros** | Telas de Materiais (lista, novo, editar, inativar e reativar) e Dados da empresa, e o bloqueio de "Novo orçamento" sem empresa completa. | F2 |
| **V2-D Orçamentos salvos** | Lista (código, cliente, data, total, status), detalhes em leitura com Editar, Excluir com confirmação e alternância de status, dashboard (D-32), PDF e WhatsApp adaptados aos totais e snapshots, sem redesenhar o layout (prompt §1). | F2 |
| **V2-E Agenda** | Melhorias do cronograma (seção 6). | F2 |
| **V2-G Acabamento** | Telas pequenas e contraste nas telas novas, README, conferência dos requisitos e novo APK. | todas |

A, B, C, D e E rodam em paralelo depois da F2. A e B compartilham o
controller da edição, que é congelado na F2: se uma delas precisar de
operação nova, pede por handoff. F1 e F2 podem ser feitas pelo mesmo agente,
em sequência.

**Riscos:**
- **F2 é grande.** Troca o modelo em todo o app de uma vez e quebra cerca de
  120 testes, que precisam ser reescritos junto. Mitigação: a F1 já entrega
  o domínio testado; a F2 só conecta.
- **SQLite nos testes.** Os testes de repositório usam
  `sqflite_common_ffi` em memória. Os testes de widget sobrescrevem os
  repositórios, como hoje fazem com o armazenamento.
- **PDF:** o layout comercial é "outra tarefa" no prompt. A V2-D só troca os
  dados de origem; o redesenho fica para depois.

Documentos afetados:
- `01-requisitos` e `02-decisoes`;
- `04-plano`, com a nova rodada;
- `CLAUDE.md` e `.cursorrules` (o modelo de domínio);
- tarefas novas em `docs/tarefas/v2/`.

As tarefas T2, T3, T5 e T6 da rodada anterior ficam como histórico.

## 6. Agenda: o que melhorar

Entram nesta rodada os itens **1, 2, 3, 4 e 7**. Os itens 5 e 6 ficam para
depois (dependência nova e tela grande); dá para trocar até a V2-E começar.

O agendamento "ficou legal" e pode ser otimizado. Candidatos, para escolher
ou trocar:
1. **Aba própria** (D-31): a agenda sai de "Mais" e vira aba.
2. **Exemplos com datas de hoje** (HO-T8-01): em debug, "hoje" deixa de
   abrir vazio.
3. **Criar tarefa a partir do orçamento:** nos detalhes, um botão "Agendar"
   já preenche o vínculo e o título (ex: "Produção 281026-03").
4. **Tarefas do orçamento nos detalhes:** lista das tarefas vinculadas.
5. **Lembrete no celular** antes da tarefa. Exige dependência nova de
   notificações locais e permissão no Android 13+.
6. **Visão de semana** além do mês.
7. **Tarefas atrasadas:** destaque para as pendentes de dias anteriores.
