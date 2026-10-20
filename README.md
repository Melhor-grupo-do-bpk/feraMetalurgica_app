# FERA

App de gestão de orçamentos para uma empresa de estruturas metálicas
(portões basculantes, estruturas treliçadas, grades de proteção). Permite
montar, calcular e enviar orçamentos B2B, com catálogo de produtos e
cronograma de tarefas.

- **Plataformas:** Android e iOS.
- **Persistência:** local, em arquivos JSON (sem backend por enquanto —
  trocável por API depois sem mudar as camadas `domain`/`presentation`).

O projeto Flutter fica em [`fera_metalurgica_app/`](fera_metalurgica_app/).
As regras de estrutura e convenções para quem (ou qual IA) for editar este
repositório estão em [`CLAUDE.md`](CLAUDE.md) (espelhado em `.cursorrules`).

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47.1 (versão
  fixada em [`fera_metalurgica_app/.fvmrc`](fera_metalurgica_app/.fvmrc)).
  Recomendado usar o [FVM](https://fvm.app/) para garantir que todo o time
  use exatamente essa versão:
  ```bash
  dart pub global activate fvm
  cd fera_metalurgica_app
  fvm install
  fvm use
  # depois disso, rode os comandos abaixo com "fvm flutter" / "fvm dart"
  ```
- No Windows, o Modo de Desenvolvedor precisa estar ativado para builds com
  plugins (symlinks): `start ms-settings:developers`.

## Como rodar

```bash
cd fera_metalurgica_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Geração de código (build_runner)

O projeto usa `freezed`, `json_serializable` e `riverpod_generator`. Os
arquivos gerados (`*.g.dart`, `*.freezed.dart`) **não são versionados** —
gere-os localmente sempre que der `pub get` ou alterar um model `@freezed`
ou um provider `@riverpod`:

```bash
# gera uma vez
dart run build_runner build --delete-conflicting-outputs

# gera continuamente enquanto você edita
dart run build_runner watch --delete-conflicting-outputs
```

## Como rodar os testes

```bash
flutter test
```

Ver [`fera_metalurgica_app/test/README.md`](fera_metalurgica_app/test/README.md)
para a convenção de testes (`unit/`, `widget/`, `mocks/`).

## Lint / análise estática

O projeto usa [`very_good_analysis`](https://pub.dev/packages/very_good_analysis).
O CI (`.github/workflows/analyze.yml`) roda `flutter analyze --fatal-infos`
em todo Pull Request — nenhum erro ou aviso de lint pode ficar sem correção.

## Planejamento

Requisitos, decisões, padrões e o plano de desenvolvimento em trilhas
paralelas ficam em [`docs/`](docs/README.md). Leia antes de começar uma
tarefa.

## Estrutura de pastas

```
fera_metalurgica_app/
  lib/
    core/            # infraestrutura compartilhada
      di/            # providers riverpod compartilhados (ex: LocalJsonStorage)
      router/        # AppRoutes (mapa de rotas) + appRouter (go_router)
      theme/         # AppTheme + tokens (cores, textos, espaçamentos)
      utils/         # utilitários genéricos (storage, datas, máscaras...)
      widgets/       # componentes visuais compartilhados
      constants/     # constantes globais
    features/
      dashboard/     # tela inicial com indicadores e recentes
      orcamentos/     # CRUD + wizard de orçamentos
      catalogo/       # catálogo de produtos/estruturas
      cronograma/     # calendário e tarefas
      mais/           # menu da aba "Mais"
  test/
    unit/    widget/    mocks/
```

Cada feature segue `data/` (implementações/I-O) + `domain/` (models freezed
+ contratos de repositório) + `presentation/` (telas/widgets) + um arquivo
barrel `<feature>.dart` com a API pública da feature.

## Features

- **dashboard** — tela inicial com indicadores (orçamentos em andamento,
  aguardando aprovação, aprovados, pedidos em produção) e lista de
  orçamentos recentes.
- **orcamentos** — CRUD de orçamentos e wizard de criação em 4 etapas
  (1. dados do cliente, 2. itens/medidas/material, 3. custos operacionais,
  4. resumo com valor final calculado), detalhes do orçamento, geração/prévia
  de PDF e envio via WhatsApp.
- **catalogo** — catálogo de produtos/estruturas (foto, categoria, descrição
  técnica).
- **cronograma** — calendário e lista de tarefas do dia, filtráveis por tipo
  (orçamentos/produção/visitas).
- **mais** — menu da aba "Mais" (hoje: Cronograma).

> Estado atual: fundação das telas (F1) pronta — rotas, estado compartilhado,
> utilitários e dados de exemplo; as telas ainda são stubs e são
> implementadas nas trilhas T2–T8 de [`docs/04-plano.md`](docs/04-plano.md).
