# Prompt: módulo de orçamento (modelo por peças) e adaptação do fluxo beta

## 1. Contexto e objetivo

Você vai evoluir o módulo de montagem de orçamentos de um app Flutter/Dart (app embarcado, não web) para uma empresa que fabrica produtos sob medida. O orçamento é montado por produtos, e cada produto é composto por **peças**. Cada peça usa um material e tem medidas próprias. O preço do produto é um **preço base de fabricação** somado ao **custo calculado dos materiais** das peças.

**Já existe um fluxo de orçamento beta implementado no app.** O trabalho não é recomeçar do zero: é levar o que existe para o modelo descrito aqui, reaproveitando o que for compatível. A seção 11 explica como.

Este prompt consolida o relatório "Projeto FERA: relatório funcional e modelo de classes" (v1.0, 27 out 2026). Se o relatório estiver disponível no repositório, use-o como referência complementar. Em caso de conflito entre ele e este prompt, pergunte antes de decidir.

**Escopo:** apenas o módulo de orçamento. Não há emissão fiscal nem controle de estoque. Geração de PDF, envio por WhatsApp e layout do documento comercial pertencem a outra tarefa. Este módulo só precisa garantir que o modelo de dados e a prévia consigam alimentá-la depois.

## 2. Decisões consolidadas

- Todas as peças são fabricadas pela empresa. Não há compra de peças prontas nesta versão.
- O valor de fabricação é próprio de cada produto: **preço base por unidade do produto**, sem repetir mão de obra em cada peça.
- O material é cobrado **pela medida usada na peça** (área ou volume). Não cobrar chapa inteira nem aplicar perdas automaticamente.
- Um produto tem **uma ou mais peças**, e cada peça tem **exatamente um material**. Se uma peça precisar de dois materiais, são duas linhas.
- **Sem rascunho persistido.** O orçamento em edição vive só em memória e é gravado apenas ao finalizar.
- Dados de material, cliente e empresa são **copiados** para o orçamento (cópia histórica). Alterar cadastros depois não muda orçamentos finalizados.
- Armazenamento local, fluxo em 4 etapas.

| Conceito | Significado |
|---|---|
| Material | Matéria-prima de referência, por exemplo "Madeira - espécie A" ou "Granito - variedade B - 2 cm". |
| Produto / item do orçamento | O que é vendido ao cliente. No código é `ItemOrcamento`; na interface aparece como "Produto". |
| Peça | Componente físico usado para fabricar **uma unidade** do produto. Uma linha pode representar várias peças idênticas. |
| Preço base | Valor de fabricação e demais componentes comerciais que o emitente quer acrescentar, **sem** o material calculado. Rótulo na tela: "Preço base de fabricação por produto (sem materiais)". |
| Snapshot | Cópia dos dados que preserva o que foi realmente usado no orçamento. |

## 3. Cadastros

### 3.1 Material

| Campo | Regra |
|---|---|
| nome | Obrigatório. Deve identificar a variação que muda o preço (espécie, acabamento, espessura). |
| unidade | `M2` ou `M3`. |
| precoReferencia | Dinheiro, maior que zero. Na interface o rótulo é "preço de referência" (não é média calculada). |
| ativo | Padrão `true`. Inativo não aparece em novas seleções. |

- Ao selecionar o material em uma peça, copiar nome, unidade e preço. O preço copiado é **editável na peça** e a alteração **não volta ao cadastro**.
- **Inativar em vez de excluir.** Para trocar a unidade de uma referência já usada, cadastrar outra referência e inativar a anterior. Nunca reinterpretar preços antigos.

### 3.2 Empresa (emitente)

Um registro por instalação: nome/razão social, CPF/CNPJ, telefone, endereço e e-mail opcional. Se os dados obrigatórios estiverem incompletos, bloquear "Novo orçamento" e levar à configuração. A cópia do emitente é criada ao iniciar o fluxo.

### 3.3 Cliente

Nome, celular, CPF/CNPJ e endereço, todos obrigatórios. Busca por nome, celular ou documento. Selecionar preenche uma **cópia editável** no orçamento. O cadastro só é criado ou atualizado ao finalizar. O **documento normalizado é a chave única**: nome ou telefone iguais não bastam para mesclar pessoas. Se o operador mudar o documento de um cliente já selecionado, resolver a identidade de novo e avisar que pode ser outro cadastro.

### 3.4 Produto e peça

São registros internos do orçamento, sem tela de cadastro própria e sem catálogo.

| Agrupar na mesma linha | Criar outra linha |
|---|---|
| Quatro pernas com mesmo material, dimensões e preço aplicado. | Duas pernas longas e duas curtas, ou mesmo material com preços diferentes. |
| Duas mesas com composição e preço base idênticos. | Duas mesas parecidas com medidas, composição ou preço base diferentes. |

Há duas quantidades distintas: **quantidade por produto** (na peça) diz quantas peças são necessárias para fabricar um produto; **quantidade de produtos** (no item) diz quantos produtos iguais serão vendidos.

## 4. Fluxo de telas

| Etapa | Operação e resultado |
|---|---|
| Início | Lista de orçamentos finalizados (número, cliente, data, total). Botões "Novo orçamento", "Materiais" e "Dados da empresa". Abrir um orçamento salvo em modo leitura. Excluir com confirmação. |
| 1. Cliente | Selecionar ou preencher o cliente. Validar obrigatórios. Alterações ficam só na sessão de edição. |
| 2. Produtos | Criar produto (descrição, quantidade, preço base, observações opcionais) e abrir sua composição de peças. Mostrar subtotal por produto e total dos produtos. |
| Composição do produto | Adicionar peça: material, preço aplicado, dimensões em cm, quantidade por produto. Mostrar consumo, custo unitário e custo da linha. |
| 3. Valores | Insumos, impostos, combustível, outros (com descrição), desconto, validade e observações. Total geral não editável. |
| 4. Prévia | Emitente, cliente, produtos, quantidades, preços e totais. Voltar para corrigir. "Finalizar" grava tudo e gera número e data. |

### Comportamento da etapa 2 e da composição

- **Formulário da peça:** descrição, material (só ativos, com atalho para cadastrar), preço aplicado (copiado, editável, mostrando R$/m² ou R$/m³ e indicando quando difere do cadastro), comprimento, largura e espessura em cm, quantidade por produto, observações opcionais.
- Dimensões ficam **indisponíveis até selecionar o material**. Em m², exigir comprimento e largura. Em m³, exigir também espessura. Em m², a espessura pode ser informada como dado técnico opcional, **sem efeito na fórmula**.
- **Resumo ao vivo:** por peça (consumo, custo unitário, custo da linha) e por produto (custo dos materiais, preço unitário, total do item).
- Trocar o material substitui a referência copiada e o preço, avisando se havia preço ajustado. Se a unidade mudar, exigir revisão das dimensões antes de aceitar a peça.
- Produtos e peças podem ser editados, duplicados e removidos. **Duplicar gera novos identificadores e listas independentes** (cópia profunda).
- Ao adicionar uma peça, limpar o formulário de peça. Ao adicionar um produto, limpar o formulário de produto. Se houver campos preenchidos e não adicionados ao avançar, avisar.
- Quantidade zero ou peça incompleta impedem avançar.

### Navegação, descarte e prévia

- As 4 etapas compartilham um estado único. Voltar não perde dados. Ao sair do fluxo, pedir confirmação de descarte. Perder a sessão se o app fechar de forma inesperada é aceito.
- A prévia é **comercial por produto**, com o detalhe de peças disponível internamente. Se os custos de material aparecem na versão entregue ao cliente, e o layout de impressão, ficam para definição posterior.
- Construir a prévia como widget separado, alimentado só pelos dados do `Orcamento`, para reaproveitar no PDF depois.

## 5. Cálculos e precisão

Comprimento, largura e espessura em **centímetros**; nos cálculos, ÷ 100. O consumo pertence a **uma unidade física da peça**. A quantidade por produto multiplica o custo da peça. A quantidade de produtos só multiplica o resultado final do produto.

```
C = comprimentoCm / 100     L = larguraCm / 100     E = espessuraCm / 100

M2: consumoUnitario = C × L
M3: consumoUnitario = C × L × E

custoUnitarioPeca     = arredondarCentavos(consumoUnitario × precoAplicado)
custoLinhaPeca        = custoUnitarioPeca × quantidadePorProduto
custoMateriaisProduto = soma dos custoLinhaPeca
precoUnitarioProduto  = custoMateriaisProduto + precoBase
totalItem             = precoUnitarioProduto × quantidadeProdutos
totalProdutos         = soma dos totalItem
subtotal              = totalProdutos + insumos + impostos + combustivel + outros
totalGeral            = subtotal − desconto
```

**Política de precisão:**
- **Dinheiro:** inteiro em centavos. Preço de referência e preço base aceitam duas casas. **Nunca `double` em cálculo monetário.**
- **Dimensões:** decimal exato em cm, até duas casas na entrada. Conversões e produtos **sem arredondar o consumo intermediário**. Persistir decimais como texto canônico.
- **Arredondamento:** half-up (metade para cima) no **custo de uma peça**. Depois multiplicar por inteiros e somar em centavos. A interface usa a mesma política.
- **Exibição:** dinheiro em pt-BR; consumo com precisão suficiente (até 12 casas quando necessário). Valor abreviado para exibição nunca é reutilizado como entrada de cálculo.
- Exemplo: 0,005 m² a R$ 1,00/m² dá R$ 0,005, arredondado para R$ 0,01 por peça; três peças somam R$ 0,03. Arredondar só a soma daria outro resultado. Não misturar as políticas.

## 6. Validações e regras de negócio

| Área | Regra |
|---|---|
| Material | Nome obrigatório; unidade M2 ou M3; preço de referência e preço aplicado maiores que zero; só ativos em novas seleções. |
| Peça | Descrição, material e dimensões aplicáveis obrigatórios. Quantidade por produto inteira ≥ 1. Dimensões positivas, até duas casas em cm. |
| Produto | Descrição obrigatória; quantidade inteira ≥ 1; preço base não negativo; pelo menos uma peça válida. |
| Orçamento | Empresa e cliente válidos; pelo menos um produto válido; nenhum formulário incompleto ignorado ao finalizar. |
| Adicionais | Insumos, impostos, combustível e outros não negativos, padrão zero. Exigir descrição quando "outros" for maior que zero. |
| Desconto | Não negativo e no máximo igual ao subtotal. Total geral nunca negativo. Total zero deve ser destacado para conferência. |
| Validade | Opcional; se preenchida, inteiro positivo em dias corridos a partir da emissão; exibir a data-limite calculada. |
| Cliente | Obrigatórios conforme 3.3; documento normalizado e validado pelo tipo (CPF/CNPJ). Documento e celular são texto, nunca número. |
| Entrada | Aceitar pt-BR; rejeitar valores inválidos. Campo vazio durante a edição não equivale a dimensão zero válida. |

- **Cobrança duplicada:** o preço base pertence a uma unidade completa do produto; insumos e demais adicionais pertencem ao orçamento. O operador deve incluir cada despesa em apenas um lugar, e a interface deve explicar essa separação. O app não deduz o que já foi embutido no preço base.
- **Limite do cálculo:** o sistema calcula material, preço base e adicionais informados. Não avalia se o valor cobre todos os custos nem calcula lucro.
- **Formas irregulares:** esta versão só calcula retângulos (área) e blocos retangulares (volume). Não tratar peça circular ou irregular como retangular de forma silenciosa.
- **Histórico:** editar empresa, cliente ou material não modifica orçamentos finalizados. Consulta de orçamento antigo mostra os **totais armazenados**, sem recalcular. Excluir um orçamento remove seus itens e peças, nunca os cadastros. **Números excluídos não são reutilizados.**

## 7. Modelo de classes

Tipos conceituais em Dart; `?` indica opcional.

### Objetos de valor
- **Dinheiro** (`centavos: int`): imutável; somar, subtrair, comparar, multiplicar por inteiro e formatar pt-BR. Converter entrada textual sem passar por `double`.
- **MedidaCm** (`valor: Decimal`): maior que zero quando exigida; até duas casas na entrada; `emMetros()` divide exatamente por 100.
- **UnidadeCobranca**: enum `M2`, `M3` com códigos estáveis. Outras unidades exigiriam nova estratégia de cálculo e validação.
- **Documento** (`tipo: CPF|CNPJ`, `valorNormalizado: String`): normaliza a máscara e valida por tipo, com validador dedicado.
- **Endereco**: `logradouro`, `numero` (texto, aceita "s/n"), `bairro`, `cidade`, `uf`; `cep` e `complemento` opcionais.

### Cadastros
- **Material**: `id`, `nome`, `unidade`, `precoReferencia: Dinheiro`, `ativo`. Métodos: `validar()`, `gerarSnapshot()`.
- **Empresa**: `id`, `nomeRazaoSocial`, `documento`, `telefone`, `endereco`, `email?`. Métodos: `validar()`, `estaCompleta()`, `gerarSnapshot()`.
- **Cliente**: `id`, `nome`, `documento`, `celular`, `endereco`. Métodos: `validar()`, `gerarSnapshot()`.

### Snapshots (imutáveis, sem CRUD)
- **MaterialSnapshot**: `materialOrigemId?`, `nome`, `unidade`, `precoReferenciaCopiado`, `precoAplicado`. Ajustar o preço cria nova cópia; a diferença entre os dois preços sinaliza ajuste na interface.
- **ClienteSnapshot** e **EmpresaSnapshot**: cópias completas dos dados, com `...OrigemId?`.
- Vínculos de origem servem para rastreio, nunca para recalcular. Origem ausente não invalida a cópia.

### Composição do orçamento
- **PecaOrcamento**: `id`, `descricao`, `quantidadePorProduto: int` (≥ 1), `material: MaterialSnapshot`, `comprimentoCm`, `larguraCm`, `espessuraCm?` (obrigatória em M3; em M2 é informativa), `observacoes?`. Métodos: `validar()`, `copiarCom(...)`, `duplicar(novoId)`.
- **ItemOrcamento**: `id`, `descricao`, `quantidadeProdutos: int` (≥ 1), `precoBase: Dinheiro` (≥ 0), `pecas: List<PecaOrcamento>` (≥ 1), `observacoes?`. Métodos: `validar()`, `copiarCom(...)`, `duplicarComNovosIds()` (cópia profunda).
- **Orcamento** (documento final imutável): `id`, `numero: int`, `chaveFinalizacao: String`, `dataEmissao: DateTime`, `cliente: ClienteSnapshot`, `emitente: EmpresaSnapshot`, `itens`, `insumos`, `impostos`, `combustivel`, `outros`, `outrosDescricao?`, `desconto`, `validadeDias?`, `observacoes?`, `totais: ResultadoOrcamento`, `versaoCalculo: int`. Sem setters; `dataValidade` derivada quando houver prazo.
- **OrcamentoEmEdicao**: sessão transitória em memória, com `chaveFinalizacao`, cópias editáveis de cliente e emitente, itens, adicionais, desconto, validade e observações. Sem número nem data definitivos; pode estar incompleta. Campos de texto de formulários incompletos são estado de interface: peça e item só entram na lista depois de validados.
- **Invariantes:** cada peça pertence a um único item; cada item, a um único orçamento. A quantidade de produtos nunca altera a `quantidadePorProduto` das peças.

### Resultados (imutáveis)
- **ResultadoPeca**: `pecaId`, `unidade`, `consumoUnitario`, `consumoLinha: Decimal`, `custoUnitario`, `custoLinha: Dinheiro` (valores físicos por um produto).
- **ResultadoItem**: `itemId`, `pecas`, `custoMateriais`, `precoUnitario`, `totalItem` (já considera `quantidadeProdutos`).
- **ResultadoOrcamento**: `itens`, `totalProdutos`, `totalAdicionais`, `subtotal`, `desconto`, `totalGeral`.

### Serviços
- **CalculadoraOrcamento**: `versaoCalculo`; `calcularPeca`, `calcularItem`, `calcularOrcamento`. Serviço puro e determinístico: não acessa banco, cadastro atual, relógio nem widgets. Rejeita total negativo.
- **ValidacaoService**: `validarDocumento`, `validarCliente`, `validarEmpresa`, `validarPeca`, `validarItem`, `validarOrcamento`. Retorna `ErroValidacao` (`caminhoCampo`, `codigo`, `mensagem`), por exemplo `itens[0].pecas[1].espessuraCm`. Não altera dados em silêncio. Falhas de banco são tratadas separadamente.
- **FinalizarOrcamentoService**: dependências `CalculadoraOrcamento`, `ClienteRepository`, `OrcamentoRepository`, `SequenciaRepository`, `UnidadeDeTrabalho` e `Relogio` (abstração pequena para obter a data). `executar(edicao) → Orcamento`.

### Controller
**OrcamentoController** (`ChangeNotifier` com Provider): `edicao: OrcamentoEmEdicao?`, `etapaAtual` (1 a 4, voltar sempre permitido), `resumo: ResultadoOrcamento?` (derivado só de dados válidos), `erros`, `finalizando: bool` (bloqueia clique repetido e alterações durante a gravação).
Operações: `iniciar`, `selecionarCliente`, `atualizarCliente`, `adicionar/editar/remover/duplicarItem`, `adicionar/editar/remover/duplicarPeca`, `atualizarValores`, `avancar`, `voltar`, `recalcular`, `finalizar`, `descartar`.
Usa cópias independentes e notifica a interface. Não contém SQL nem fórmulas. `finalizar()` delega ao serviço e só limpa a sessão após sucesso. `descartar()` roda depois da confirmação da interface.

### Repositórios (interfaces independentes da biblioteca)
- **MaterialRepository**: `listarAtivos(filtro)`, `buscarPorId`, `salvar`, `inativar`.
- **EmpresaRepository**: `obter`, `salvar` (garante um único emitente).
- **ClienteRepository**: `buscarPorDocumento`, `pesquisar(termo)`, `salvar` (unicidade do documento normalizado).
- **OrcamentoRepository**: `listarResumos`, `buscarPorId`, `buscarPorChaveFinalizacao`, `inserirCompleto`, `excluir`. Sem atualização de conteúdo finalizado.
- **SequenciaRepository**: `proximoNumero()` dentro da transação, com contador independente dos registros existentes.
- **UnidadeDeTrabalho**: `executarEmTransacao(operacao)`; tudo confirma ou tudo desfaz.
- **Não criar** `ProdutoRepository` nem `PecaRepository`: o orçamento é o agregado que grava sua composição.

## 8. Arquitetura, persistência e finalização

| Camada | Escolha |
|---|---|
| Interface | Widgets Flutter para dinheiro, medidas, composição e resumo. Exibem resultados, não definem fórmulas. |
| Estado | `OrcamentoController` com `ChangeNotifier` e Provider. |
| Domínio | Entidades, objetos de valor, validações e `CalculadoraOrcamento`, sem dependência da biblioteca de persistência. |
| Aplicação | `FinalizarOrcamentoService` coordena validação, cálculo, número e gravação. |
| Persistência | SQLite local atrás de repositórios. O adaptador concreto segue o que o projeto já usa; se mudar, justifique no plano. |

**Gravação única ao finalizar:**
1. Revalidar todo o orçamento e recalcular os totais (não confiar só nas telas).
2. Abrir transação. Resolver, criar ou atualizar o cliente pelo documento normalizado.
3. Reservar o próximo número no contador persistido, atribuir a data de emissão e gravar orçamento, cópias, itens, peças e totais.
4. Confirmar a transação. Só então limpar a edição e voltar à lista. Se falhar, desfazer tudo e manter os dados em memória para nova tentativa.
5. Bloquear clique duplo em "Finalizar". Usar `chaveFinalizacao` como chave idempotente: repetir a mesma chave devolve o documento já gravado e não cria outro. Isso não transforma a sessão em rascunho persistido.

**Estrutura física:** tabelas `materiais`, `empresa`, `clientes`, `orcamentos`, `itens_orcamento`, `pecas_orcamento` e `sequencias`. Cópias de cliente e empresa podem ficar serializadas no orçamento; a cópia de material fica em cada peça. Impor unicidade de `numero`, `chaveFinalizacao` e documento normalizado do cliente. Excluir orçamento exclui seus itens e peças, nunca materiais nem clientes. Persistir a ordem de itens e peças. Dinheiro em centavos inteiros e medidas como decimais serializados sem perda. Guardar versão do esquema e versão do cálculo (separadas). Uso local: sem sincronização, múltiplos emitentes ou vários dispositivos.

## 9. Exemplos e critérios de aceite (testes)

Os preços são fictícios e servem de casos de teste.

**A. Mesa de granito e madeira.** Produto "Mesa de jantar sob medida", 2 mesas, preço base R$ 800,00 por mesa.

| Peça / material | Qtd por mesa | Dimensões (cm) | Preço aplicado | Custo da linha |
|---|---|---|---|---|
| Tampo / granito | 1 | 180 × 90 | R$ 300,00/m² | R$ 486,00 |
| Perna / madeira | 4 | 75 × 8 × 8 | R$ 3.500,00/m³ | R$ 67,20 |

Tampo: 1,62 m² × 300 = 486,00. Uma perna: 0,0048 m³ × 3.500 = 16,80; quatro: 67,20. Materiais por mesa: **R$ 553,20**. Preço unitário: **R$ 1.353,20**. Total do item (2 mesas): **R$ 2.706,40**. Consumo total informativo: 3,24 m² de granito e 0,0384 m³ de madeira (nunca somar m² com m³ nem cobrar o material outra vez).

**B. Painel em MDF.** 3 painéis, uma peça de 120 × 60 cm, R$ 90,00/m², base R$ 150,00: 0,72 m² → R$ 64,80 de material → **R$ 214,80** por painel → **R$ 644,40** no item.

**C. Fechamento com A e B.** Produtos R$ 3.350,80; insumos 100,00; impostos 200,00; combustível 50,00; outros 30,00; subtotal R$ 3.730,80; desconto 100,00; **total geral R$ 3.630,80**.

**Outros cenários obrigatórios:**
- **Modelo antigo em m³:** uma peça 200 × 90 × 8 cm a R$ 3.500,00/m³ → R$ 504,00 de material; base R$ 800,00 → **R$ 1.304,00** por produto.
- **Medidas diferentes, linhas separadas:** pernas de 75 × 8 × 8 (duas) = R$ 33,60; de 70 × 8 × 8 (duas) = R$ 31,36; total das pernas **R$ 64,96**.
- **Precisão:** 0,005 m² × R$ 1,00 = R$ 0,01 por peça; três peças = R$ 0,03.
- **Mudança de preço no cadastro:** a peça salva continua em R$ 90,00/m² (painel R$ 214,80). Nova seleção sugere o preço atual (a R$ 100,00/m²: material R$ 72,00, painel R$ 222,00).
- **Preço ajustado só na peça:** R$ 95,00/m² → material R$ 68,40, painel R$ 218,40. O cadastro permanece em R$ 90,00 e o ajuste fica claro no resumo da peça.
- **Troca de unidade:** m² → m³ exige espessura válida; m³ → m² deixa de multiplicar a espessura.
- **Histórico:** editar ou inativar material não altera orçamento salvo.
- **Duplicação e navegação:** editar a cópia não muda o original; voltar entre etapas preserva dados; sair pede confirmação de descarte.
- **Validação e transação:** quantidade zero, desconto maior que o subtotal e peça incompleta bloqueiam a finalização; falha de gravação não deixa registros parciais.
- **Repetição:** clique duplo ou repetição da mesma `chaveFinalizacao` não cria dois orçamentos.

## 10. Fora do escopo

Estoque, compras, emissão fiscal, cálculo automático de impostos, catálogo de produtos e peças, perdas automáticas, chapa inteira, peças compradas, margem percentual automática, sincronização, rascunhos persistidos, edição de orçamentos finalizados, peças de formato irregular, e geração de PDF, WhatsApp e layout do documento comercial (outra tarefa).

## 11. Adaptação do fluxo beta já implementado

Não escreva nem altere código antes de concluir os passos 1 a 4 e receber minha confirmação.

**1. Inventário (somente leitura).** Leia primeiro `AGENTS.md`, `CLAUDE.md` e a documentação em `docs/` (requisitos, decisões, padrões, plano). Depois mapeie no código do beta:
- Modelos de orçamento, item, material, cliente e empresa.
- Telas e controller do fluxo, e como o estado é compartilhado.
- Persistência: biblioteca, esquema, versão e dados já gravados.
- Onde ficam os cálculos e que tipos numéricos usam.
- Testes existentes.
- O que outras partes do app (lista e detalhes, PDF/WhatsApp) consomem do orçamento.

**2. Análise de lacunas.** Monte uma tabela "O que existe | O que este prompt exige | Ação (manter, ajustar, substituir ou criar)". Verifique em especial:
- Um material por item, em vez de peças com material próprio.
- Dinheiro ou dimensões em `double`.
- Existência de cópias (snapshots) de material, cliente e empresa.
- Rascunho persistido.
- Número sequencial e gravação em transação.
- Material com `ativo` e preço editável na peça sem alterar o cadastro.
- Adicionais, desconto e validações.
- Descarte ao sair e cliente identificado pelo documento.

**3. Migração de dados.** Se o beta já gravou dados, proponha uma estratégia e espere minha decisão:
- Cada item antigo vira um produto com **uma peça** (`quantidadePorProduto = 1`), com o material copiado, as dimensões do beta e o preço base mantido.
- Materiais antigos entram como `ativo = true`.
- Valores `double` viram centavos com arredondamento half-up, documentado.
- Orçamentos finalizados do beta **mantêm os totais já gravados** (não recalcular) e recebem uma versão de cálculo que os identifique como legado.
- Se os dados do beta forem só de teste, a alternativa é recriar o banco. **Não apague nem sobrescreva dados sem minha confirmação**, e faça backup antes de qualquer migração. As migrações devem ser versionadas.

**4. Plano e confirmação.** Apresente: o que será reaproveitado, o que será substituído, a ordem dos passos, os arquivos afetados, os riscos e as tarefas em `docs/tarefas/` impactadas pela mudança de modelo (por exemplo wizard, lista e detalhes, PDF/WhatsApp). Inclua as decisões que precisam de mim. Aguarde a confirmação.

**5. Execução incremental.** Depois de confirmado:
1. Objetos de valor, modelos, `CalculadoraOrcamento` e testes com os cenários da seção 9.
2. Esquema, migração, repositórios e transação de finalização.
3. Cadastros de material (com inativação) e empresa, e busca de cliente por documento.
4. Controller e composição de produtos e peças.
5. Telas: etapa 2 com composição; ajustes nas etapas 1, 3 e 4; início e histórico; validação do fluxo completo.

Regras de execução: o app deve continuar compilando e rodando a cada passo; commits pequenos; `flutter analyze` e `flutter test` limpos; remover código legado só depois de substituído e coberto por teste; seguir os padrões do repositório.

**6. Documentação e paralelismo.** Atualize os documentos de requisitos, decisões e plano com o novo modelo e registre o que as tarefas dependentes precisam rever. Se houver agentes trabalhando em paralelo, os itens 1 e 2 (modelo, cálculo, esquema e repositórios) fazem parte da fundação e devem ser concluídos e mesclados antes das telas. Quem trabalha nas telas não altera modelo nem calculadora: sinaliza a necessidade.

## 12. Forma de trabalho

1. Primeiro o inventário, a análise de lacunas, a estratégia de migração e o plano (seção 11). Só depois do meu "ok" você escreve código.
2. Entregue os arquivos individualmente, sem compactar em ZIP.
3. Se alguma regra for ambígua ou entrar em conflito com o código existente, pergunte antes de decidir por conta própria.
4. Ao final de cada etapa, informe o que mudou, o que foi reaproveitado, os testes executados e as pendências.
