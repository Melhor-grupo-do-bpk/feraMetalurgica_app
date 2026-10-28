# Decisões

Registro de como resolvemos cada ponto em que as telas do Figma, o modelo de
dados do [`CLAUDE.md`](../CLAUDE.md) e o que falta definir com o cliente não
batiam. **Uma decisão registrada aqui vale mais que a imagem da tela.** Para
mudar uma decisão, edite o item e anote a data. Para criar uma nova, adicione
um `D-xx` no fim (ver [`README.md`](README.md)).

Os itens marcados com `TODO(cliente)` são provisórios: implemente como
descrito e deixe o comentário `// TODO(cliente): …` no código, para que seja
fácil encontrar quando o cliente responder.

---

### D-01
**Itens não têm valor; só existe o valor final.** *(Telas 6 e 7)*

As telas 6 e 7 mostram valor unitário, unidade (pç, m², h), subtotal e
"Total Geral" por item. O modelo diz que itens são descritivos e que o valor
vem dos custos operacionais. **Vale o modelo.**

- Item na tela ou no PDF: `tipoServico` como título; linha com
  `medidas.formatada` e `materialPrincipal` (o que existir, separados por
  " • "); `especificacoes`; e "Qtd: N un".
- Não existe campo de unidade: a quantidade é sempre "un".
- Um único valor por orçamento: `Orcamento.valorFinal`, rotulado "Valor
  Final" na tela e "Valor Total" no PDF. Sem subtotal, desconto ou "Total
  Geral".

### D-02
**"Nome do projeto" é um campo no topo da etapa 2.** *(Telas 3 e 5)*

O resumo mostra "PROJETO", mas nenhuma etapa pede esse dado. O campo
"Nome do projeto" entra no topo da etapa 2, antes do formulário de item, e
é opcional na tela. Se ficar vazio ao concluir, `projeto` recebe o
`tipoServico` do primeiro item. O modelo não muda (`projeto` já existe).

### D-03
**Como cada indicador do dashboard é contado.** *(Tela 1)*

| Card | Regra |
|---|---|
| Orçamentos em andamento | `status == emAnalise` |
| Aguardando aprovação | `status == enviado` |
| Aprovados | `status == aprovado` |
| Pedidos em produção | tarefas com `tipo == producao` e `concluida == false` |

`rascunho` e `recusado` não entram em nenhum card. "Orçamentos Recentes"
também ignora rascunhos. A contagem fica num provider de
`features/dashboard/presentation/`, que lê os providers de orçamentos e
tarefas pelos barrels.

### D-04
**Validade e dados do emissor são constantes.** *(Telas 6 e 7)* `TODO(cliente)`

- `AppConstants.validadeOrcamentoDias = 15`.
- `AppConstants.emissorNome`, `emissorCnpj`, `emissorEndereco`,
  `emissorCidade` e `emissorTelefone`, com os valores do Figma (Fera
  Metalurgica LTDA, 00.000.000/0001-00, Av. Industrial, 1000 - Galpão 4,
  São Paulo - SP, (11) 99999-9999).
- O cliente **não tem endereço** no modelo, e não vamos criar o campo. O PDF
  mostra nome, CPF/CNPJ, telefone e e-mail (se houver).

### D-05
**`Tarefa` ganha `descricao` e `orcamentoId`; a tela de cronograma mostra 3 filtros.** *(Tela 10)*

A tela mostra a descrição ("Cliente: Indústrias Apex S/A", "Linha de
montagem B…") e o vínculo "Ver Detalhes" com um orçamento. Por isso o modelo
de tarefa ganha:

- `descricao` (`String?`): texto livre abaixo do título;
- `orcamentoId` (`String?`): id de um `Orcamento`. Quando existe, aparece
  "Ver Detalhes".

A hora vem de `data` (que já é `DateTime`). O botão "Preparar Linha" do Figma
**não** será implementado, porque não tem ação definida. Os filtros são 3
caixas (Orçamentos, Produção, Visitas), todas marcadas por padrão, porque a
própria tela mostra uma tarefa de produção. O estado do filtro não é
persistido.

### D-06
**Fluxo de status do orçamento.** *(Telas 6 e 8)*

```
(wizard) → emAnalise ──WhatsApp──▶ enviado ──▶ aprovado
                │                      └─────▶ recusado
                └── menu "Alterar status" permite qualquer um dos 4 abaixo
```

- O wizard grava `emAnalise` ao criar e preserva o status ao editar.
- Enviar WhatsApp com sucesso muda `emAnalise` para `enviado`, e apenas a
  partir de `emAnalise`.
- Nos detalhes, um botão de menu (⋮) no card do cliente abre "Alterar status"
  com Em análise, Enviado, Aprovado e Recusado. `rascunho` não aparece no
  menu.

### D-07
**O wizard não salva rascunho.** `TODO(cliente)`, o mesmo de `status_orcamento.dart`

O wizard só grava no fim. Sair dele com dados preenchidos pede confirmação
("Descartar orçamento?"). O status `rascunho` continua existindo: o chip
"Rascunhos" da lista funciona e os dados de exemplo têm um rascunho.

### D-08
**Margem e prazo continuam provisórios.** `TODO(cliente)`

- A margem segue em 62,5% (`AppConstants.margemPadraoPercentual`).
- O prazo segue com 15 dias úteis (`Orcamento.prazoDiasUteis`).
- Nenhuma tela edita margem ou prazo por enquanto. Ambos aparecem apenas
  para leitura.

### D-09
**Identificadores.**

- **Orçamento**: número sequencial com 5 dígitos (`"00483"`). Uma função
  pura `proximoIdOrcamento(List<Orcamento>)` em
  `orcamentos/domain/calculo_orcamento.dart` retorna o maior id numérico + 1,
  com zeros à esquerda, ou `"00001"` se a lista estiver vazia. Exibição:
  `#00483` nas telas e `Nº 00483` no PDF.
- **Demais ids** (cliente, item, tarefa): UUID v4 via `gerarId()` em
  `core/utils/id_generator.dart` (pacote `uuid`).

### D-10
**Ignorar estes erros do Figma.**

- O campo "Email do cliente" repetido na etapa 2 (Tela 3).
- O número "Nº 2023-1048" e as datas de 2023 nas Telas 7 e 10 (o formato
  segue D-09).
- "CPF do cliente" na Tela 2: o rótulo passa a ser "CPF/CNPJ do cliente",
  porque o modelo aceita os dois e o público é B2B.

### D-11
**Mapa de rotas.** *(definido na F1, ver `AppRoutes`)*

| Rota | Tela | Shell (nav inferior)? |
|---|---|---|
| `/` | Dashboard | sim |
| `/orcamentos` | Lista de orçamentos | sim |
| `/orcamentos/novo?produtoId=` | Wizard (novo) | não |
| `/orcamentos/:id` | Detalhes | não |
| `/orcamentos/:id/editar` | Wizard (edição) | não |
| `/orcamentos/:id/pdf` | Prévia do PDF | não |
| `/catalogo` | Catálogo | sim |
| `/mais` | Menu Mais | sim |
| `/mais/cronograma` | Cronograma | sim |
| `/mais/cronograma/tarefa?id=` | Formulário de tarefa (nova ou edição) | não |

- Telas "não shell" usam `parentNavigatorKey: rootNavigatorKey`.
- `novo` é declarada antes de `:id`.
- A etapa do wizard é estado do controller, **não** parte da URL.
- Navegue sempre por helpers de `AppRoutes` (ex:
  `AppRoutes.detalhesOrcamento(id)`), nunca com strings soltas.

### D-12
**Cada feature declara suas próprias rotas.** *(evita conflito em paralelo)*

Cada feature expõe suas rotas em `presentation/<feature>_routes.dart`,
exportado pelo barrel, e `core/router/app_router.dart` apenas as compõe.
Depois da F1, **`app_router.dart` e `AppRoutes` (`app_routes.dart`) estão congelados**: as
trilhas só trocam o `builder` das rotas da própria feature (que nascem
apontando para `PlaceholderPage`).

### D-13
**Aba Mais vira a feature `mais`.**

`lib/features/mais/` (só `presentation/` e o barrel) contém o menu da aba.
Hoje o menu tem apenas "Cronograma". Configurações, notificações etc. entram
aqui no futuro.

### D-14
**Dependências novas.**

- A F1 adiciona `uuid` (D-09), `url_launcher` (D-15) e
  `flutter_localizations` (SDK), para que `showDatePicker`, `showTimePicker`
  e os textos do Material fiquem em pt-BR.
- `pdf` e `printing` (usados pela T5, D-15) já estavam no projeto antes da
  F1.
- Calendário e máscaras são feitos à mão, sem pacote: calendário em
  `cronograma/presentation/`, máscaras e validadores em `core/utils/`.
- Qualquer outra dependência exige uma nova decisão aqui.

### D-15
**Envio por WhatsApp.**

Abre `https://wa.me/55<somente-dígitos>?text=<mensagem>` com
`url_launcher` (`LaunchMode.externalApplication`). A mensagem tem saudação,
número do orçamento, projeto, valor final, prazo e validade. O `wa.me` não
aceita anexo, então o PDF é compartilhado pelo botão "Baixar" da prévia
(`Printing.sharePdf`). Se o número tiver menos de 10 dígitos ou o WhatsApp
não abrir, a tela mostra um `SnackBar` e o status não muda.

### D-16
**O documento do cliente nunca mostra custos internos.**

Custos operacionais e total de custos aparecem **só** na etapa 3 do wizard.
Resumo (etapa 4), detalhes, PDF e mensagem do WhatsApp mostram apenas o
valor final.

### D-17
**Dados de exemplo só no primeiro uso em modo debug.**

`LocalJsonStorage` ganha `Future<bool> exists(String fileName)`. Em
`main.dart`, quando `kDebugMode` for verdadeiro e o arquivo da feature ainda
não existir, os seeds (`orcamentosSeed`, `catalogoSeed`, `cronogramaSeed`) são
gravados pelos repositórios. Em release, o app começa vazio, exceto pelo
catálogo, que é sempre semeado se o arquivo não existir, porque é o
catálogo real da empresa.

### D-18
**Catálogo só para leitura; as fotos ficam em assets.**

- Não há tela de criar ou editar produto (o Figma não tem).
- Fotos ficam em `assets/images/catalogo/<id>.jpg`. Se `fotoPath` começa com
  `assets/`, use `Image.asset`; senão, `Image.file`. Sem foto ou com erro,
  mostre um placeholder com ícone.
- Categorias dos chips = categorias distintas dos produtos, em ordem
  alfabética.

### D-19
**Sino de notificações sem tela.**

O sino continua na `AppTopBar` sem ação (`onNotificationsPressed: null`).
Não implemente notificações sem uma nova decisão.

### D-20
**"Tipo do serviço" vem do catálogo, com opção "Outro".**

A lista de seleção mostra os nomes dos produtos do catálogo e, no fim,
"Outro". Escolher um produto define `tipoServico = produto.nome` e
`produtoId = produto.id`. "Outro" abre um campo de texto livre e deixa
`produtoId = null`.

### D-21
**Estado do wizard.**

Um único `@riverpod class OrcamentoWizardController` (autoDispose), em
`orcamentos/presentation/wizard/`, guarda a etapa atual e um `Orcamento` em
construção. Ele tem métodos por etapa (`atualizarCliente`, `adicionarItem`,
`atualizarCustos`…), validação por etapa e `concluir()`, que salva pelo
provider de orçamentos e retorna o id. Recebe `orcamentoId?` (edição) ou
`produtoId?` (vindo do catálogo) como parâmetro de família.

### D-22
**Filtros da lista de orçamentos.**

Chips nesta ordem: Todos, Rascunhos, Em análise, Enviados, Aprovados,
Recusados. A busca e o filtro se combinam, e o estado deles fica num provider
da tela (não é persistido).

### D-23
**PF ou PJ é deduzido do CPF/CNPJ.**

O cliente ganha um getter (não um campo) `Cliente.ehPessoaJuridica`: 14
dígitos indica PJ, qualquer outro valor indica PF. Para isso, `Cliente`
precisa do construtor `const Cliente._()`. Exibição: "Cliente PF" ou
"Cliente PJ".

### D-24
**Ícone e splash gerados por pacotes de desenvolvimento.** *(T8, 28/10/2026)*

Complementa a D-14. Entram só como `dev_dependencies`
`flutter_launcher_icons` e `flutter_native_splash`, configurados no fim do
`pubspec.yaml`, apenas para Android e iOS (web, Windows e macOS
desligados). O app não importa nenhum dos dois em `lib/`.

- Imagens-fonte em `assets/launcher/` (fora do bundle), feitas a partir de
  `assets/images/logo_fera.png` (só o "F"): `icone.png` (fundo branco),
  `icone_adaptativo.png` (ícone adaptativo do Android, fundo `#FFFFFF`),
  `splash.png` e `splash_android12.png`.
- Splash: fundo `AppColors.light.background` (`#FDF8F8`) e, no modo escuro,
  `AppColors.dark.background` (`#141312`), com o "F" no centro.
- Para regerar: `dart run flutter_launcher_icons` e
  `dart run flutter_native_splash:create`. O `flutter_launcher_icons` troca
  `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` no
  `project.pbxproj` do iOS: reverta essa mudança antes de commitar.
- `TODO(cliente)`: logo completo, com o texto "FERA METALURGICA", para o
  splash e o PDF.
