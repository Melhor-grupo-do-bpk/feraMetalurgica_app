# FERA — regras para agentes de IA (Claude Code, Cursor, Copilot, etc.)

Este arquivo é a fonte única de regras estruturais do projeto. Todo assistente
de IA que editar este repositório deve segui-lo. O mesmo conteúdo está
espelhado em `.cursorrules`; mantenha os dois em sincronia se um for editado.

Baseado nas diretrizes oficiais de estilo Dart/Flutter (Effective Dart,
`docs.flutter.dev/ai`) somadas às regras específicas deste projeto abaixo, que
têm prioridade em caso de conflito.

## Planejamento (leia antes de qualquer tarefa)

O **o quê** e o **quando** do desenvolvimento ficam em [`docs/`](docs/):
requisitos por tela, decisões que resolvem as divergências entre o Figma
(`Teste/`) e o modelo, padrões de telas, controllers, testes e git, o plano
de fases com trilhas paralelas e uma tarefa por trilha. Comece por
[`docs/README.md`](docs/README.md). Regras resumidas:

- **Uma decisão em `docs/02-decisoes.md` vale mais que a imagem do Figma.**
  Não há decisão para o caso? Pare e pergunte, depois registre um `D-xx`.
- Trabalhe em uma única trilha (`docs/tarefas/`) e só nos arquivos que ela
  possui (tabela em `docs/04-plano.md`). Após a F1, `core/`, `domain/`,
  `data/`, barrels, `*_routes.dart`, `*_controller.dart`, `main.dart` e
  `pubspec.yaml` estão congelados: mudanças neles vão em PR separado.
- Siga `docs/03-padroes.md` (estrutura de `presentation/`, Riverpod,
  navegação, testes, commits e Definition of Done).
- **Desenvolvimento paralelo por agentes**: branches, worktrees, posse de
  arquivos, contratos, handoffs e integração estão em
  [`docs/orquestracao.md`](docs/orquestracao.md). Nesta rodada ele vale
  sobre a seção 6 (Git e PR) de `docs/03-padroes.md`, e mudanças em
  arquivos congelados são pedidas por handoff, não por PR separado.

## Sobre o app

FERA é um app de gestão de orçamentos para uma empresa de estruturas
metálicas (portões basculantes, estruturas treliçadas, grades de proteção).
Permite montar, calcular e enviar orçamentos B2B, com cadastro de materiais
e da empresa e agenda de tarefas. Android e iOS (e Windows, para
desenvolvimento). Sem backend: persistência local em SQLite (D-27), num
banco único aberto em `lib/core/di/banco_de_dados.dart`, atrás dos
repositórios de cada feature.

## Estrutura de pastas (feature-first)

```
lib/
  core/
    di/          # providers compartilhados (banco SQLite e esquema, agora)
    domain/      # objetos de valor compartilhados (Dinheiro, MedidaCm, Documento...)
    router/      # AppRouter (go_router) — única fonte de rotas do app
    theme/       # AppTheme + tokens (AppColors, AppTextStyles, AppSpacing)
    widgets/     # componentes visuais compartilhados (AppTopBar, StatCard...)
    utils/       # utilitários genéricos (ex: formatação, linha_sql)
    constants/   # constantes globais (ex: AppConstants)
  features/
    dashboard/
    orcamentos/
    materiais/   # cadastro de materiais (D-26)
    empresa/     # dados da empresa emitente (D-26)
    clientes/    # cadastro de clientes (D-26)
    cronograma/  # aba "Agenda" (D-31)
    mais/        # só presentation: menu da aba "Mais" (D-13)
```

Cada feature em `features/<nome>/` tem exatamente:

- `domain/` — modelos (freezed) e contratos de repositório (`abstract class
  XRepository`). Sem I/O, sem Flutter widgets.
- `data/` — implementações de repositório (ex: `SqliteXRepository`, que
  recebe o executor do sqflite, banco ou transação, no construtor) e os
  providers riverpod que as expõem. Aqui, e só aqui, entra I/O (SQL,
  `path_provider`, etc).
- `presentation/` — widgets, telas, controllers/notifiers riverpod da UI.
- `<nome>.dart` — barrel: único ponto de import público da feature. Código
  fora da feature importa `features/<nome>/<nome>.dart`, nunca arquivos
  internos de `data/`/`domain/`/`presentation/` diretamente.

Não crie pastas globais por tipo na raiz de `lib/` (`models/`, `widgets/`,
`services/`, `screens/`, etc.). Se um arquivo não se encaixa em `core/` nem em
uma feature existente, pare e pergunte antes de criar uma categoria nova.

## Regras específicas (não negociáveis)

1. **Não crie uma segunda versão de um utilitário/repositório que já existe
   em outro lugar.** Antes de escrever um novo helper, storage, ou
   repository, procure por algo equivalente em `core/` ou na feature
   relevante e reutilize/estenda.
2. **Todo modelo de dado usa `freezed` + `json_serializable`.** Nunca crie uma
   classe de modelo manual (com `copyWith`/`==`/`toJson` escritos à mão).
   Padrão usado neste projeto: `@freezed abstract class X with _$X { const
   factory X({...}) = _X; const X._(); factory X.fromJson(...) => ...; }`
   (o construtor nomeado `._()` — quando existir, para getters computados —
   vem depois do `factory` no código, mas veja a ordem exigida pelo lint
   `sort_unnamed_constructors_first`: o construtor default/factory sem nome
   vem primeiro no arquivo gerado; siga o padrão dos arquivos existentes em
   `lib/features/orcamentos/domain/`).
3. **Toda tela tem rota no `go_router`.** O mapa de rotas e os helpers ficam
   em `AppRoutes` (`lib/core/router/app_routes.dart`, D-11). Cada feature
   declara suas rotas em `presentation/<feature>_routes.dart`, e o
   `app_router.dart` só as compõe (D-12). Nunca use
   `Navigator.push`/`Navigator.of(context).push` diretamente nas features:
   isso quebra o deep linking e a navegação centralizada do `go_router`.
4. **Gerência de estado é riverpod (`@riverpod`/`riverpod_annotation`) com
   `build_runner`.** Não introduza outro gerenciador de estado (Bloc,
   Provider clássico, GetX, `setState` para estado compartilhado entre
   widgets, etc).
5. **Rode `flutter analyze` mentalmente antes de considerar a tarefa
   concluída.** O projeto usa `very_good_analysis` com `--fatal-infos` no CI
   — nenhuma regra de lint pode ficar violada, e nenhuma regra pode ser
   desativada em `analysis_options.yaml` sem pedido explícito do usuário.
   Lembre de rodar `dart run build_runner build --delete-conflicting-outputs`
   depois de mexer em qualquer modelo freezed/provider riverpod, já que
   `*.g.dart`/`*.freezed.dart` não são versionados.
6. **Cores só em `lib/core/theme/app_colors.dart`.** Nenhum `Color(0x...)`
   fora desse arquivo; widgets leem `context.colors` (claro/escuro), textos
   usam `AppTextStyles` e espaçamentos `AppSpacing`. Antes de criar um widget
   visual, veja se já existe um equivalente em `lib/core/widgets/`.
7. **Todo repository novo precisa de teste correspondente** em `test/unit/`
   (e um mock em `test/mocks/` se outras camadas dependem dele). Veja
   `test/README.md`.

## Domínio do negócio — não invente campos fora disso

Modelo de dados da rodada v2 (D-26 a D-30), com todos os modelos em
`freezed` + `json_serializable`. Notação: `?` = opcional, `= x` = valor
padrão. Campos fora desta lista exigem alinhamento antes. O modelo completo,
as fórmulas e as regras de validação estão nas seções 5 a 7 de
[`docs/prompt-modulo-orcamento-v2.md`](docs/prompt-modulo-orcamento-v2.md).
As decisões D-26 a D-30 valem sobre o prompt.

**Precisão (D-26): nunca `double` em dinheiro, medida ou consumo.**

### Objetos de valor (`lib/core/domain/`)

- **`Dinheiro`** — `centavos` (`int`). Operadores `+`, `-`, `*` (por `int`)
  e comparações; `formatado` (`R$ 1.234,56`). `tryParse`/`parse` leem
  pt-BR sem `double`:
  - vírgula decimal, com ou sem ponto de milhar (`"1.234,56"`);
  - ponto decimal só sem vírgula e com 1 ou 2 dígitos depois (`"7.5"`);
  - ponto com 3 dígitos é milhar (`"1.500"`);
  - mais de 2 casas, sinal ou texto vazio dão `null`.

  JSON: `int` (`DinheiroJsonConverter`).
- **`MedidaCm`** — `centesimos` (`int`) de cm, com a mesma leitura pt-BR.
  Vazio dá `null`, nunca zero. JSON: `int` (`MedidaCmJsonConverter`).
- **`Consumo`** — `unidade` + `valor` (`BigInt` × 10¹², exato). Só soma
  com a mesma unidade. JSON: `{"unidade": "m3", "valor": "0.004800000000"}`.
- **`UnidadeCobranca`** — `m2`, `m3`, serializada pelo nome. Reexportada
  por `materiais.dart`.
- **`Documento`** — `valorNormalizado` (só dígitos, texto). Getter `tipo`
  (`cpf`/`cnpj`): 14 dígitos indica CNPJ (D-23). JSON: texto
  (`DocumentoJsonConverter`).
- **`Endereco`** — `logradouro`, `numero` (texto, aceita "s/n"), `bairro`,
  `cidade`, `uf` (2 letras maiúsculas), `cep?`, `complemento?`. Getter
  `formatado` (uma linha).
- **`ErroValidacao`** — `caminhoCampo` (ex:
  `itens[0].pecas[1].espessuraCm`), `codigo` (`CodigoErroValidacao`) e
  `mensagem`. As validações comuns ficam em `validacao_comum.dart`.

### Cadastros (`materiais/`, `empresa/`, `clientes/`)

- **`Material`** — `id`, `nome`, `unidade`, `precoReferencia`
  (`Dinheiro`), `ativo` (`= true`). Inativar substitui excluir.
  `MaterialRepository`: `listarAtivos({filtro})`, `listarTodos`,
  `buscarPorId`, `salvar`, `inativar`, `reativar`, `estaEmUso` (D-40). Atenção: o nome colide
  com o widget `Material` do Flutter.
- **`Empresa`** — `id`, `nomeRazaoSocial`, `documento`, `telefone`,
  `endereco`, `email?`. Getter `estaCompleta`.
  `EmpresaRepository`: `obter`, `salvar` (um emitente só).
- **`Cliente`** — `id`, `nome`, `documento` (chave única normalizada),
  `celular`, `endereco`, todos obrigatórios.
  `ClienteRepository`: `buscarPorDocumento`, `pesquisar(termo)`, `salvar`.

### Orçamentos (`lib/features/orcamentos/domain/`)

Um orçamento é composto por produtos (`ItemOrcamento`), e cada produto, por
peças. Cada peça tem um material copiado.

- **Snapshots** — `MaterialSnapshot` (`nome`, `unidade`,
  `precoReferenciaCopiado`, `precoAplicado`, `materialOrigemId?`; getter
  `precoAjustado`), `ClienteSnapshot` e `EmpresaSnapshot` (cópias
  completas, com `...OrigemId?`). São gerados por `material.gerarSnapshot()`,
  `cliente.gerarSnapshot()` e `empresa.gerarSnapshot()`, extensões
  definidas no arquivo de cada snapshot. Mudar o cadastro não altera
  orçamentos.
- **`PecaOrcamento`** — `id`, `descricao`, `quantidadePorProduto` (≥ 1),
  `material`, `comprimentoCm`, `larguraCm`, `espessuraCm?` (obrigatória em
  m³, informativa em m²), `observacoes?`. Método `duplicar(novoId)`.
- **`ItemOrcamento`** — `id`, `descricao`, `quantidadeProdutos` (≥ 1),
  `precoBase` (≥ 0, sem materiais), `pecas` (≥ 1), `observacoes?`. Método
  `duplicarComNovosIds(gerarId)`, uma cópia profunda.
- **`StatusOrcamento`** (D-29) — `criado` e `enviado`, serializados pelo
  nome. Editar um orçamento `enviado` o devolve para `criado`.
- **`Orcamento`** (D-30) — campos:
  - identificação: `id` (UUID), `codigo` (`DDMMAA-NN`, ex: `281026-03`),
    `revisao`, `chaveFinalizacao`;
  - datas: `criadoEm`, `atualizadoEm` e `enviadoEm?` (preenchida ao
    passar para `enviado`, limpa ao voltar para `criado`; mudar o status
    não mexe no `atualizadoEm`, HO-V2-F2-01/D-37);
  - `status`, `cliente`, `emitente`, `itens`;
  - adicionais: `insumos`, `impostos`, `combustivel`, `outros`,
    `outrosDescricao?`, `desconto`;
  - `validadeDias?`, `observacoes?`;
  - `totais` (`ResultadoOrcamento`) e `versaoCalculo`.

  Getters: `codigoExibicao` (`281026-03 rev. 2` a partir da 2ª revisão),
  `totalGeral` e `dataValidade` (contada de `atualizadoEm`).
- **`OrcamentoEmEdicao`** — a sessão do wizard, só em memória e sem totais.
  - `cliente?` e `emitente`;
  - `itens = []` e adicionais `= Dinheiro.zero`;
  - `orcamentoOrigemId?`, `codigo?` e `revisao?` na edição de um orçamento
    salvo.
- **Resultados** — `ResultadoPeca`, `ResultadoItem` e `ResultadoOrcamento`,
  gravados no orçamento. `ResultadoOrcamento.totalGeralZero` sinaliza o
  total zero, que é permitido.
- **Código** — `formatarCodigoOrcamento(data, sequenciaDoDia)` e
  `lerCodigoOrcamento(codigo)`, em `codigo_orcamento.dart`.
- **Contratos de persistência** (implementados em SQLite em
  `orcamentos/data/`):
  - `OrcamentoRepository`: `listarResumos` (por `atualizadoEm`
    decrescente), `buscarPorId`, `buscarPorChaveFinalizacao`, `inserir`,
    `atualizar`, `excluir`;
  - `SequenciaRepository.proximaDoDia(data)`;
  - `UnidadeDeTrabalho.executarEmTransacao((RepositoriosTransacao repos)
    async => ...)`, em que `repos` dá acesso a `clientes`, `orcamentos` e
    `sequencias` ligados à transação.
- **`FinalizarOrcamentoService`** — o único lugar que grava um orçamento
  (criação e edição, D-30), numa transação e idempotente pela
  `chaveFinalizacao`. As telas usam o `OrcamentoController` (D-28), que o
  chama em `finalizar()`.

**Valor final: nunca é digitado nem gravado à mão.** É sempre o
`ResultadoOrcamento` calculado pela `CalculadoraOrcamento`
(`versaoCalculo = 1`, pura, em `calculadora_orcamento.dart`):

```
custoUnitarioPeca = arredondarHalfUp(consumo × precoAplicado)   (único arredondamento)
custoLinhaPeca    = custoUnitarioPeca × quantidadePorProduto
precoUnitario     = soma das linhas + precoBase
totalItem         = precoUnitario × quantidadeProdutos
subtotal          = soma dos totalItem + insumos + impostos + combustivel + outros
totalGeral        = subtotal − desconto            (nunca negativo)
```

Um orçamento salvo mostra os totais gravados, sem recalcular. Se a fórmula
mudar, altere a calculadora e a `versaoCalculo`.

As validações (`validarPeca`, `validarItem`, `validarOrcamento`, além de
`validarMaterial`, `validarEmpresa`, `validarCliente` e `validarDocumento`)
devolvem `List<ErroValidacao>` e nunca alteram os dados.

### Cronograma (`lib/features/cronograma/domain/`)

- **`Tarefa`** — `id`, `titulo`, `data` (`DateTime`, inclui a hora), `tipo`
  (`TipoTarefa`), `concluida` (`bool = false`), `descricao?`,
  `orcamentoId?` (id de um `Orcamento`, D-05; excluir o orçamento limpa
  o vínculo). `TarefaRepository`: `getAll`, `save`, `delete`.
- **`TipoTarefa`** — `orcamento`, `producao`, `visita`.

Não invente campos, entidades ou relações fora do que está descrito aqui sem
perguntar antes.

## Geração de código

```bash
dart run build_runner build --delete-conflicting-outputs   # gera uma vez
dart run build_runner watch --delete-conflicting-outputs   # gera continuamente
```

Necessário sempre que você criar/editar uma classe `@freezed` ou um provider
`@riverpod`.

## Hot reload (assistentes com MCP do Dart/Flutter configurado)

Regra oficial do Flutter (`flutter/agent-plugins`): ao editar qualquer
arquivo `.dart` em `lib/`, se você tiver acesso às ferramentas MCP do Dart
(`hot_reload`/`hot_restart`/`dtd`) e houver um app rodando, dispare
`hot_reload` após mudanças em widgets/`build()`, ou `hot_restart` após
mudanças em `initState`, estado global/estático ou `main()`. Não dispare para
mudanças em `test/**` ou apenas em comentários/whitespace. Se você não tem
essas ferramentas MCP disponíveis, ignore esta seção.
