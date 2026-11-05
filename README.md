# FERA

App de gestão de orçamentos para uma empresa de estruturas metálicas
(portões basculantes, estruturas treliçadas, grades de proteção). Permite
montar, calcular e enviar orçamentos B2B por produtos e peças, com cadastro
de materiais e da empresa e agenda de tarefas.

- **Plataformas:** Android e iOS (e Windows, para desenvolvimento).
- **Persistência:** local, num banco SQLite (sem backend; D-27), atrás dos
  repositórios de cada feature.

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
      di/            # providers compartilhados (banco SQLite e esquema)
      domain/        # objetos de valor (Dinheiro, MedidaCm, Documento...)
      router/        # AppRoutes (mapa de rotas) + appRouter (go_router)
      theme/         # AppTheme + tokens (cores, textos, espaçamentos)
      utils/         # utilitários genéricos (datas, máscaras, busca...)
      widgets/       # componentes visuais compartilhados
      constants/     # constantes globais
    features/
      dashboard/     # tela inicial com indicadores e recentes
      orcamentos/    # wizard, lista, detalhes, PDF e WhatsApp
      materiais/     # cadastro de materiais
      empresa/       # dados da empresa emitente
      clientes/      # cadastro de clientes (usado pelo wizard)
      cronograma/    # aba "Agenda": calendário e tarefas
      mais/          # menu da aba "Mais"
  test/
    unit/    widget/    mocks/
```

Cada feature segue `data/` (implementações/I-O) + `domain/` (models freezed
+ contratos de repositório) + `presentation/` (telas/widgets) + um arquivo
barrel `<feature>.dart` com a API pública da feature.

## Features

- **dashboard** — tela inicial com os indicadores (criados, enviados no
  mês, valor enviado no mês e pedidos em produção) e os 2 orçamentos mais
  recentes.
- **orcamentos** — wizard de 4 etapas (1. cliente, 2. produtos e peças,
  3. valores, 4. prévia), lista com busca e filtro, detalhes com edição
  (revisões), status, exclusão, PDF e envio por WhatsApp. O valor final é
  sempre calculado pela `CalculadoraOrcamento`, em centavos inteiros.
- **materiais** — materiais com unidade (m² ou m³) e preço de referência;
  inativar no lugar de excluir.
- **empresa** — dados do emitente dos orçamentos.
- **clientes** — cadastro criado ou atualizado ao finalizar um orçamento,
  com o documento como chave.
- **cronograma** — aba "Agenda": calendário, filtros por tipo, linha do
  tempo, tarefas atrasadas e tarefas vinculadas a orçamentos.
- **mais** — menu da aba "Mais": Materiais e Dados da empresa.

## O que o app faz hoje

Rodada v2 (orçamento por produtos e peças). Tudo funciona offline, nos
modos claro e escuro, de 360 dp a tablet:

- **Início:** "Criar orçamento", os 4 indicadores e os 2 orçamentos mais
  recentes.
- **Orçamentos:**
  - wizard que busca ou cadastra o cliente;
  - cada produto tem um preço base e peças com material, medidas em cm e
    quantidade, com o custo calculado ao vivo;
  - adicionais (insumos, impostos, combustível, outros), desconto,
    validade e observações;
  - prévia do documento antes de finalizar;
  - código `DDMMAA-NN` (ex: `281026-03`), e cada edição grava a "rev. N";
  - lista com busca e filtro Todos/Criados/Enviados;
  - detalhes com os totais gravados, Editar, Excluir, status
    criado/enviado, PDF para compartilhar e WhatsApp.
- **Agenda:** calendário do mês, filtros, linha do tempo com tarefas que
  podem ser concluídas, aviso e destaque das atrasadas, e "Agendar" a
  partir do orçamento.
- **Mais:** Materiais (lista, novo, editar, inativar e reativar) e Dados da
  empresa, sem os quais não dá para criar orçamento.

Em modo debug, o primeiro uso grava dados de exemplo: a empresa, os
materiais, os exemplos B e C do prompt e algumas tarefas (D-17, D-38). Em
release, o banco nasce vazio: o primeiro passo é cadastrar a empresa e os
materiais.

O que depende do cliente (custos de material no PDF, layout do PDF,
histórico de revisões, lembretes, logo e cores) está em
[`docs/relatorios/2026-10-28-perguntas-cliente.md`](docs/relatorios/2026-10-28-perguntas-cliente.md).

## Gerar o APK

```bash
cd fera_metalurgica_app
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Para conferir no Windows sem celular: `flutter run -d windows`.
