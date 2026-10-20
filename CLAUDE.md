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

## Sobre o app

FERA é um app de gestão de orçamentos para uma empresa de estruturas
metálicas (portões basculantes, estruturas treliçadas, grades de proteção).
Permite montar, calcular e enviar orçamentos B2B, com catálogo de produtos e
cronograma de tarefas. Android e iOS. Sem backend: persistência local em
arquivos JSON (`LocalJsonStorage`, em `lib/core/utils/`).

## Estrutura de pastas (feature-first)

```
lib/
  core/
    di/         # providers riverpod compartilhados entre features
    router/      # AppRouter (go_router) — única fonte de rotas do app
    theme/       # AppTheme + tokens (AppColors, AppTextStyles, AppSpacing)
    widgets/     # componentes visuais compartilhados (AppTopBar, StatCard...)
    utils/       # utilitários genéricos (ex: LocalJsonStorage)
    constants/   # constantes globais (ex: AppConstants)
  features/
    dashboard/
    orcamentos/
    catalogo/
    cronograma/
    mais/        # só presentation: menu da aba "Mais" (D-13)
```

Cada feature em `features/<nome>/` tem exatamente:

- `domain/` — modelos (freezed) e contratos de repositório (`abstract class
  XRepository`). Sem I/O, sem Flutter widgets.
- `data/` — implementações de repositório (ex: `LocalXRepository`) e os
  providers riverpod que as expõem. Aqui, e só aqui, entra I/O
  (`LocalJsonStorage`, `path_provider`, etc).
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
   em `AppRoutes` (`lib/core/router/app_router.dart`, D-11). Cada feature
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

Modelo final de dados (todos `freezed` + `json_serializable`; `?` = opcional,
`= x` = valor padrão). Campos fora desta lista exigem alinhamento antes.

### Orçamentos (`lib/features/orcamentos/domain/`)

Um **Orçamento** é sempre a composição de cliente + itens + custos
operacionais, que são as etapas 1 a 3 do wizard; a etapa 4 é o resumo.

- **`Orcamento`** — `id` (exibido como "#00482"), `cliente` (`Cliente`),
  `projeto` (nome do projeto), `itens` (`List<ItemOrcamento>`),
  `custosOperacionais` (`CustosOperacionais`), `status`
  (`StatusOrcamento`), `criadoEm` (`DateTime`), `prazoDiasUteis` (`int = 15`;
  provisório, nenhuma etapa do wizard pede esse dado).
- **`Cliente`** (etapa 1) — `id`, `nome`, `numero` (telefone/WhatsApp),
  `cpfCnpj`, `email?`, `observacoes?`. Getter `ehPessoaJuridica` (14
  dígitos no `cpfCnpj`; entra na F1, D-23). Sem endereço (D-04).
- **`ItemOrcamento`** (etapa 2) — `id`, `tipoServico`, `medidas`
  (`Medidas = Medidas()`), `materialPrincipal?`, `especificacoes?`,
  `quantidade` (`int = 1`), `produtoId?` (referência a um
  `ProdutoCatalogo`). Itens são descritivos: **não têm valor unitário** e não
  entram no valor final.
- **`Medidas`** — `altura?`, `largura?`, `comprimento?` (A, L, C, em metros).
  Para exibir, use o getter `Medidas.formatada` (só as preenchidas, ordem
  A x L x C, ex: "2.50m x 2.20m"; vazio se nenhuma).
- **`CustosOperacionais`** (etapa 3) — `materiaPrima`, `maoDeObra`,
  `insumos`, `combustivel`, `impostos` (todos `double = 0`).
- **`StatusOrcamento`** — `rascunho`, `emAnalise`, `enviado`, `aprovado`,
  `recusado`. Não adicione outros status sem alinhar com o time. É
  serializado pelo **nome** (`"emAnalise"`), nunca pelo índice — não renomeie
  valores existentes sem migrar os dados salvos. Regras do `rascunho`:
  - os cards (indicadores) e os "recentes" do dashboard **ignoram**
    orçamentos em rascunho (regras de cada card em D-03);
  - a lista de orçamentos mostra o chip "Rascunho";
  - por enquanto o wizard só grava `emAnalise` ao concluir; salvar como
    rascunho fica para quando o cliente confirmar (`// TODO(cliente)` em
    `status_orcamento.dart`).

**Valor final** — **não é um campo digitado**. É sempre calculado:

```
valorFinal = custos × (1 + margem)
```

ou seja, getter `Orcamento.valorFinal` =
`calcularValorFinal(calcularTotalCustos(custosOperacionais), margem)`, com as
funções puras em `orcamentos/domain/calculo_orcamento.dart` e a margem padrão
em `AppConstants.margemPadraoPercentual` (provisória: 62,5%, que leva
R$ 5.200 a R$ 8.450). Se a lógica mudar, mude essas funções — nunca adicione um
campo `valorFinal` gravável no freezed.

### Catálogo (`lib/features/catalogo/domain/`)

- **`ProdutoCatalogo`** — `id`, `nome`, `categoria`, `descricaoTecnica`,
  `fotoPath?`.

### Cronograma (`lib/features/cronograma/domain/`)

- **`Tarefa`** — `id`, `titulo`, `data` (`DateTime`, inclui a hora), `tipo`
  (`TipoTarefa`), `concluida` (`bool = false`), `descricao?`,
  `orcamentoId?` (id de um `Orcamento`; os dois últimos entram na F1, D-05).
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
