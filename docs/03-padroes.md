# Padrões de código e de trabalho

Complementa o [`CLAUDE.md`](../CLAUDE.md), que continua valendo integralmente.
Este arquivo define o que o `CLAUDE.md` não cobre: como escrever telas,
controllers, testes e PRs, de modo que trilhas feitas em paralelo, por
pessoas ou IAs diferentes, saiam com o mesmo formato.

## 1. Organização dentro de `presentation/`

Uma subpasta por tela; widgets usados por uma única tela ficam na pasta dela.

```
features/orcamentos/presentation/
  orcamentos_controller.dart     # estado compartilhado da feature (F1)
  orcamentos_routes.dart         # rotas da feature (F1, congelado)
  lista/
    orcamentos_lista_page.dart   # classe pública da tela (stub criado na F1)
    orcamento_list_card.dart     # widgets só desta tela
  detalhes/  wizard/  pdf/
```

- Arquivo `<nome>_page.dart` com a classe `<Nome>Page`. Uma classe pública
  por arquivo. Widgets auxiliares pequenos podem ser privados (`_Nome`) no
  mesmo arquivo.
- Um widget usado por **duas features ou mais** vai para
  `lib/core/widgets/`, num PR separado e pequeno (ver
  [`04-plano.md`](04-plano.md#mudanças-fora-da-sua-trilha)). Antes de criar
  um, procure em `core/widgets/`: os componentes do Figma já existem lá.

## 2. Estado (Riverpod)

- Sempre geração de código: `@riverpod`, nunca providers escritos à mão.
- **Controller da feature** (criado na F1, em
  `presentation/<feature>_controller.dart`): um `AsyncNotifier` que carrega a
  lista do repositório e expõe métodos de escrita. Depois de gravar, ele
  atualiza o próprio estado, o que reconstrói automaticamente todas as telas
  que o observam (dashboard incluído).

  ```dart
  @riverpod
  class Orcamentos extends _$Orcamentos {
    @override
    Future<List<Orcamento>> build() async { ... }   // ordenado por criadoEm desc
    Future<void> salvar(Orcamento orcamento) async { ... }
    Future<void> excluir(String id) async { ... }
  }

  @riverpod
  Future<Orcamento?> orcamentoPorId(Ref ref, String id) async { ... }
  ```

  Nomes fixos: `orcamentosProvider`, `orcamentoPorIdProvider`,
  `produtosCatalogoProvider`, `tarefasProvider`. As trilhas **podem
  adicionar** métodos a esses controllers, mas **não podem renomear nem
  remover** os que existem, porque outras trilhas dependem deles.
- **Estado de uma tela** (filtro, busca, etapa do wizard): provider próprio
  na pasta da tela, normalmente `autoDispose` (o padrão do `@riverpod`).
- `setState` só para estado efêmero e local de um widget (animação, foco,
  campo expandido). Formulários usam `ConsumerStatefulWidget` com
  `TextEditingController`s e mandam o valor para o controller da tela.
- Telas leem `AsyncValue` com `switch`/`.when` e tratam **carregando**
  (`CircularProgressIndicator` centralizado), **erro** (mensagem + botão
  "Tentar novamente", que chama `ref.invalidate`) e **vazio** (texto + ação
  principal da tela).
- Leitura de outra feature só pelo barrel:
  `import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';`.

## 3. Navegação

- Sempre por `go_router` e pelos helpers de `AppRoutes` (D-11). Nunca use
  `Navigator.push` nem strings de rota soltas.
- `context.push(...)` para abrir uma tela "por cima" (detalhes, wizard, PDF,
  formulário), o que mantém o voltar. `context.go(...)` para trocar de aba
  (ex: "Ver todos").
- Ao concluir o wizard: `context.pushReplacement(AppRoutes.detalhesOrcamento(id))`.
- Diálogos e bottom sheets (`showDialog`, `showModalBottomSheet`) são
  permitidos: não são telas e não têm rota.

## 4. Visual

- `Scaffold(appBar: AppTopBar(onBack: ...))` em todas as telas. `onBack:
  context.pop` nas telas empilhadas e `null` nas raízes de aba.
- Cores via `context.colors`, textos via `AppTextStyles` com `.copyWith(color:
  colors.x)`, espaçamentos via `AppSpacing`. Nada de `Color(0x...)`, nem
  números mágicos de padding fora de `AppSpacing`.
- Strings em pt-BR direto no código (sem i18n por enquanto).
- Dinheiro: `formatarMoeda`. Datas: `formatarData` (`dd/MM/yyyy`) e
  `formatarHora` (`HH:mm`), de `core/utils/date_format.dart` (F1). Número do
  orçamento: `'#${orcamento.id}'`.
- Rótulos de enum (status, tipo de tarefa) ficam em **extensões** na
  `presentation/` da feature (ex: `extension StatusOrcamentoUi on
  StatusOrcamento { String get label; ... }`), criadas na F1. Nunca em
  `domain/`.

## 5. Testes

| O quê | Onde | Obrigatório? |
|---|---|---|
| Função pura (cálculo, validação, máscara, formatação) | `test/unit/<arquivo>_test.dart` | sim |
| Repository / controller da feature | `test/unit/` | sim |
| Tela | `test/widget/<feature>/<tela>_page_test.dart` | sim: renderiza com dados, estado vazio e a ação principal |
| Mock novo | `test/mocks/mock_<nome>.dart` (um arquivo por mock) | quando outra camada depende dele |

- Testes de widget usam `ProviderScope(overrides: [...])`, sobrescrevendo o
  **provider do repositório** com o mock (`mocktail`), e o helper
  `test/widget/core/pump_themed.dart`.
- Dados de teste: reutilize os seeds (`orcamentosSeed` etc.) em vez de criar
  novos objetos.
- Nunca dependa de `DateTime.now()` sem controle: passe a data por parâmetro
  ou por um provider que o teste possa sobrescrever.

## 6. Git e PR

- **Branch**: `feat/<trilha>-<slug>`, a partir de `main` atualizada (ex:
  `feat/t3-wizard`, `feat/f1-fundacao-telas`).
- **Commits** em [Conventional Commits](https://www.conventionalcommits.org/),
  em pt-BR, com a feature como escopo: `feat(orcamentos): busca na lista`,
  `test(cronograma): ...`, `docs(plano): ...`. Commits pequenos e coesos.
- **Não commite**: `*.g.dart`/`*.freezed.dart`, nem mudanças locais de
  ambiente (`.fvmrc`, `windows/flutter/generated_*`, arquivos de IDE).
- Antes de abrir o PR: `git fetch && git rebase origin/main` e rode os 3
  comandos da seção 7.
- **PR**: título `[T3] Wizard de orçamento`. A descrição lista os RF
  atendidos, as decisões D-xx usadas ou criadas e o checklist da seção 7.
  Um PR por trilha. Uma trilha grande pode ter vários PRs, todos com o
  prefixo da trilha.

## 7. Pronto (Definition of Done)

- [ ] Todos os RF da trilha atendidos, ou o que faltou listado no PR.
- [ ] `dart run build_runner build --delete-conflicting-outputs` sem erro.
- [ ] `flutter analyze --fatal-infos` sem nenhum aviso.
- [ ] `flutter test` verde, com os testes novos exigidos na seção 5.
- [ ] Tela conferida contra o PDF da tela em `Teste/`, em modo claro **e**
      escuro.
- [ ] Nenhum arquivo fora da trilha alterado (ou alteração justificada no
      PR).
- [ ] `status` do arquivo da trilha atualizado.

## 8. Regras para assistentes de IA

1. Leia o `CLAUDE.md` e os arquivos desta pasta **antes** de editar
   qualquer coisa. Trabalhe em uma única trilha por vez.
2. Se a tela do Figma, o modelo e as decisões não respondem algo, **pare e
   pergunte**. Não invente campo, status, rota, dependência ou tela.
3. Antes de criar helper, widget, provider ou repositório, procure um
   equivalente (`core/`, barrels, controllers da F1).
4. Pendência que só o cliente pode resolver: implemente o provisório descrito
   em `02-decisoes.md` e deixe `// TODO(cliente): ...`.
5. Não termine a tarefa sem rodar o build_runner, o analyze e os testes. Se
   não puder rodá-los, diga isso explicitamente no resumo.
6. Ao terminar, resuma: RF feitos, arquivos tocados, decisões novas e
   pendências.
