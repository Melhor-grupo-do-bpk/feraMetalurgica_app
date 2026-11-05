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
> **Substituída pela D-26 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

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
> **Substituída pela D-26 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

**"Nome do projeto" é um campo no topo da etapa 2.** *(Telas 3 e 5)*

O resumo mostra "PROJETO", mas nenhuma etapa pede esse dado. O campo
"Nome do projeto" entra no topo da etapa 2, antes do formulário de item, e
é opcional na tela. Se ficar vazio ao concluir, `projeto` recebe o
`tipoServico` do primeiro item. O modelo não muda (`projeto` já existe).

### D-03
> **Substituída pela D-32 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

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
> **Substituída pela D-26 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

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
> **Substituída pela D-29 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

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
> **Substituída pela D-26 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

**Margem e prazo continuam provisórios.** `TODO(cliente)`

- A margem segue em 62,5% (`AppConstants.margemPadraoPercentual`).
- O prazo segue com 15 dias úteis (`Orcamento.prazoDiasUteis`).
- Nenhuma tela edita margem ou prazo por enquanto. Ambos aparecem apenas
  para leitura.

### D-09
> **Substituída pela D-30 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

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
**Envio por WhatsApp.** O envio mudou na D-43: vai o PDF, não o link.

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

> **Substituída pela D-39 na rodada v2** para os adicionais do orçamento.

### D-17
**Dados de exemplo só no primeiro uso em modo debug.**

`LocalJsonStorage` ganha `Future<bool> exists(String fileName)`. Em
`main.dart`, quando `kDebugMode` for verdadeiro e o arquivo da feature ainda
não existir, os seeds (`orcamentosSeed`, `catalogoSeed`, `cronogramaSeed`) são
gravados pelos repositórios. Em release, o app começa vazio, exceto pelo
catálogo, que é sempre semeado se o arquivo não existir, porque é o
catálogo real da empresa.

### D-18
> **Substituída pela D-31 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

**Catálogo só para leitura; as fotos ficam em assets.**

- Não há tela de criar ou editar produto (o Figma não tem).
- Fotos ficam em `assets/images/catalogo/<id>.jpg`. Se `fotoPath` começa com
  `assets/`, use `Image.asset`; senão, `Image.file`. Sem foto ou com erro,
  mostre um placeholder com ícone.
- Categorias dos chips = categorias distintas dos produtos, em ordem
  alfabética.

### D-19
**Sino de notificações sem tela.** Substituída pela D-43: o sino saiu.

O sino continua na `AppTopBar` sem ação (`onNotificationsPressed: null`).
Não implemente notificações sem uma nova decisão.

### D-20
> **Substituída pela D-31 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

**"Tipo do serviço" vem do catálogo, com opção "Outro".**

A lista de seleção mostra os nomes dos produtos do catálogo e, no fim,
"Outro". Escolher um produto define `tipoServico = produto.nome` e
`produtoId = produto.id`. "Outro" abre um campo de texto livre e deixa
`produtoId = null`.

### D-21
> **Substituída pela D-28 na rodada v2** ([`v2-plano.md`](v2-plano.md)). Vale só como histórico das telas v1.

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

### D-25
**Contraste mínimo de 4,5:1 vale mais que a cor exata do Figma.** *(T8, 28/10/2026)*

O `textContrastGuideline` do Flutter (WCAG AA) roda em todas as telas, nos
modos claro e escuro (`test/widget/telas_pequenas_test.dart`). Para passar,
alguns tokens de `app_colors.dart` mudaram o mínimo possível:

| Token | Figma | Agora | Contraste |
|---|---|---|---|
| `primary` (claro) | #BA5E1B | #B75B1A | branco: 4,46 → 4,64 |
| `onPrimary` (escuro) | branco | #141312 | sobre #D2761F: 3,31 → 5,61 |
| `onNavActive` (novo, claro e escuro) | branco | #141312 | sobre #D56D22: 3,48 → 5,34 |
| `navInactive` (escuro) | #575F67 | #A3A6A6 | sobre #141312: 2,86 → 7,57 |
| `onAccentContainer` (novo; chip "Enviado", "PRODUÇÃO") | `accent` | #A64514 / #F0965F | 3,85 → 5,02 (claro), 4,22 → 5,54 (escuro) |
| `onWhatsapp` (novo, HO-T2-01) | branco | #0B141A | sobre #25D366: 1,98 → 9,6 |

Cor nova ou alterada em `app_colors.dart` precisa continuar passando
nesse teste.

## Rodada v2 (29/10/2026)

Aprovadas com o [`v2-plano.md`](v2-plano.md). O modelo completo está na
seção 7 de [`prompt-modulo-orcamento-v2.md`](prompt-modulo-orcamento-v2.md);
as decisões abaixo registram onde o app diverge dele ou o completa.

### D-26
**Orçamento por produtos e peças.**

- Um produto (`ItemOrcamento`) tem preço base por unidade e uma ou mais
  peças. Cada peça tem um material copiado (`MaterialSnapshot`), medidas em
  cm e quantidade por produto. Cálculo, validações e exemplos: seções 5, 6 e
  9 do prompt.
- **Precisão sem pacote novo:**
  - `Dinheiro` em centavos (`int`);
  - `MedidaCm` em centésimos de cm (`int`), lida de texto pt-BR com até duas
    casas;
  - consumo exato em escala fixa de 12 casas (`BigInt`), serializado como
    texto;
  - arredondamento half-up só no custo unitário da peça;
  - nunca `double` em dinheiro, medida ou consumo.
- Objetos de valor usados por mais de uma feature (`Dinheiro`, `MedidaCm`,
  `Documento`, `Endereco`) ficam em `lib/core/domain/`.
- **Saem:**
  - a margem e o `CustosOperacionais`, substituídos por preço base,
    adicionais e desconto;
  - o `projeto`, que vai para a descrição do produto ou as observações;
  - o prazo de entrega, que vai para as observações se o cliente quiser;
  - o e-mail e as observações do cliente;
  - as constantes de emissor e validade, substituídas pelo cadastro da
    empresa e pelo `validadeDias?` por orçamento.
- O cliente ganha `endereco` obrigatório e passa a ter cadastro próprio, com o
  documento normalizado como chave única.
- Ninguém informa o valor final: ele é sempre o `ResultadoOrcamento`
  calculado pela `CalculadoraOrcamento` e gravado ao salvar. Um orçamento
  salvo mostra os totais gravados, sem recalcular.

### D-27
**SQLite.**

- Dependências novas: `sqflite` (app) e `sqflite_common_ffi` (testes e
  execução no Windows).
- Todos os dados do app ficam no SQLite, inclusive as tarefas do cronograma.
  O esquema é versionado, com migrações em `onUpgrade`.
- Gravações de vários registros rodam numa transação
  (`UnidadeDeTrabalho`).
- O `LocalJsonStorage` e os arquivos JSON do beta deixam de ser usados. Não
  há migração dos dados do beta, que são só de teste.

### D-28
**Estado da edição com Riverpod.**

O `OrcamentoController` do prompt é um Notifier Riverpod (regra 4 do
`CLAUDE.md`), não `ChangeNotifier`/Provider. Tem as mesmas operações e o
mesmo estado:
- `edicao`, `etapaAtual`, `resumo`, `erros` e `finalizando`;
- `iniciar`, `selecionarCliente`, `atualizarCliente`;
- adicionar, editar, remover e duplicar item e peça;
- `atualizarValores`, `avancar`, `voltar`, `finalizar`, `descartar`.

Fórmulas ficam na `CalculadoraOrcamento` e gravação no serviço de
finalização; o controller não tem nem um nem outro.

### D-29
**Status `criado` e `enviado`.**

- `StatusOrcamento` tem só `criado` e `enviado`, serializados pelo nome.
- Ao salvar, o orçamento fica `criado`. Enviar pelo WhatsApp com sucesso
  muda para `enviado`.
- Nos detalhes, dá para alternar manualmente entre os dois.
- A lista filtra por Todos, Criados e Enviados.

### D-30
**Código, edição e revisão.**

- **Identificador interno:** `id` UUID.
- **Código exibido:** `DDMMAA-NN`, o dia, o mês e o ano (2 dígitos) da
  criação mais a sequência do dia, com dois dígitos (ou mais, se passar de 99). Ex: `281026-03`.
  - O contador de cada dia fica persistido e nunca volta atrás, então
    excluir um orçamento não libera o código.
  - Exibição: `281026-03` nas telas e `Nº 281026-03` no PDF.
- **Edição:** orçamentos salvos podem ser editados. "Editar" reabre o wizard
  com uma cópia do orçamento, e salvar grava a nova versão no lugar da
  anterior, em transação:
  - `revisao + 1` e `atualizadoEm` com a data atual;
  - totais recalculados;
  - cliente e empresa copiados de novo dos cadastros atuais. As peças mantêm
    os materiais copiados, salvo se o operador trocar.
- **Status na edição:** se o orçamento estava `enviado`, volta para
  `criado`.
- **Exibição da revisão:** a partir da 2ª revisão, telas, PDF e WhatsApp
  mostram "rev. N".
- **Histórico:** só a revisão atual é guardada.
- **Validade:** conta a partir de `atualizadoEm`.
- **Gravação dupla:** a `chaveFinalizacao` evita gravar duas vezes no clique
  duplo, tanto ao criar quanto ao editar.

### D-31
**Catálogo removido e Agenda como aba.**

- Sai a feature `catalogo` inteira: aba, rotas, repositório, seed, fotos e
  testes, e o `produtoId` do item.
- A navegação inferior fica Início, Orçamentos, Agenda e Mais. A Agenda é
  o cronograma, que sai de "Mais".
- "Mais" passa a ter "Materiais" e "Dados da empresa".

### D-32
**Cards do dashboard.**

| Card | Conta |
|---|---|
| Criados | orçamentos com status `criado` |
| Enviados no mês | orçamentos `enviado` com `enviadoEm` no mês atual (D-37) |
| Valor enviado no mês | soma do total geral desses mesmos orçamentos |
| Pedidos em produção | tarefas de produção pendentes (como antes) |

Os "recentes" são os 2 orçamentos de `atualizadoEm` mais recente.

### D-33
**Dependências da rodada v2.** Complementa a D-14.

Só entram `sqflite` e `sqflite_common_ffi` (D-27). Notificações locais e
pacotes de decimal ficam de fora: a precisão segue a D-26.

### D-34
**Detalhes do domínio v2 definidos na F1** (HO-V2-F1-02 a 07 e 09 a 11).

- **`Consumo` no JSON:** leva a unidade, no formato
  `{"unidade": "m3", "valor": "0.004800000000"}`. `ResultadoPeca.unidade` é
  um getter.
- **Snapshots:** `gerarSnapshot()` são extensões no arquivo de cada
  snapshot. Os cadastros não importam `orcamentos`.
- **Validações:**
  - as comuns (`ErroValidacao`, documento, endereço, texto, telefone,
    e-mail) ficam em `core/domain/`;
  - as de cada cadastro ficam na própria feature;
  - as do orçamento ficam em `validacao_orcamento.dart`.

  O `X.validar()` do prompt equivale a `validarX(x)`, e o `copiarCom` ao
  `copyWith`.
- **`UnidadeCobranca`:** fica em `core/domain/`, reexportada por
  `materiais.dart`.
- **`listarResumos()`:** devolve `Future<List<Orcamento>>`, ordenado por
  `atualizadoEm` decrescente. Não existe `ResumoOrcamento`.
- **Total zero:** sinalizado por `ResultadoOrcamento.totalGeralZero`; não é
  erro de validação.
- **Endereço:**
  - logradouro, número (texto, aceita "s/n"), bairro e cidade são
    obrigatórios;
  - UF tem 2 letras maiúsculas;
  - CEP é opcional e, se informado, tem 8 dígitos;
  - celular e telefone usam `validarTelefone` (10 ou 11 dígitos);
  - o e-mail da empresa usa `validarEmail`.
- **`UnidadeDeTrabalho`:** `executarEmTransacao<T>(Future<T>
  Function(RepositoriosTransacao repos))`, sem `Zone`.
  `RepositoriosTransacao` expõe `clientes`, `orcamentos` e `sequencias`
  ligados à transação.
- **`CalculadoraOrcamento`:**
  - `calcularOrcamento` recebe parâmetros nomeados, para servir ao
    orçamento salvo e à edição;
  - `versaoCalculo` é `static const`;
  - total negativo e peça em m³ sem espessura lançam `ArgumentError`, e a
    validação barra os dois antes.

### D-35
**Leitura de números com ponto** (HO-V2-F1-08).

Em `Dinheiro` e `MedidaCm`:
- sem vírgula e com 1 ou 2 dígitos depois de um único ponto, o ponto é
  decimal (`"7.5"`);
- com 3 dígitos depois do ponto, ou vários grupos, o ponto é milhar
  (`"1.500"`);
- com vírgula, ela é decimal e o ponto é milhar.

Muitos teclados numéricos de celular só têm ponto.

### D-36
**O nome `Material` fica** (HO-V2-F1-10).

O prompt usa `Material` em todo o modelo. Nos arquivos de tela que usam o
`Material` do domínio, importe o Flutter com
`import 'package:flutter/material.dart' hide Material;`. Se o arquivo
precisar dos dois, use um prefixo no barrel de materiais.

### D-37
**Data de envio** (HO-V2-F2-01, aprovada em 29/10/2026).

- O `Orcamento` guarda `enviadoEm` (`DateTime?`), preenchido com o "agora"
  quando o status passa para `enviado`, pelo WhatsApp ou à mão.
- Volta a `null` quando o status volta para `criado`, inclusive na edição
  de um orçamento enviado (D-30).
- Reenviar um orçamento já enviado mantém a data do primeiro envio.
- Mudar o status não altera o `atualizadoEm`; a validade continua contando
  dele.
- Os cards de envio do dashboard (D-32) contam por `enviadoEm`.

### D-38
**Persistência e navegação definidas na F2** (HO-V2-F2-02).

- **Dependências:** `sqflite_common_ffi` fica em `dependencies`, porque o
  `main.dart` o usa no desktop. No Windows não é preciso DLL.
- **Tarefas:** `CronogramaRepository` virou `TarefaRepository`, com os
  mesmos métodos e o mesmo `tarefasProvider`. `tarefas.orcamento_id` tem
  chave estrangeira com `ON DELETE SET NULL`: excluir o orçamento mantém a
  tarefa e tira o vínculo.
- **Exemplos de debug (D-17):** gravados pelo serviço de finalização, com
  status `criado`, em dias anteriores (o C anteontem, o B ontem). O
  primeiro orçamento do dia é o `-01`.
- **Empresa incompleta:** as rotas do wizard, de novo e de edição,
  redirecionam para "Dados da empresa".
- **Rotas:** `/agenda` e `/agenda/tarefa?id=&orcamentoId=`; sai
  `/mais/cronograma`; `novoOrcamento()` sem `produtoId`.
  `context.push<String>(AppRoutes.material())` devolve o id do material
  salvo.
- **Código do dia:** a sequência usa a data local do "agora"
  (`AAAA-MM-DD`).
- **Edição:** a chave de finalização da sessão substitui a anterior na
  mesma linha, para o clique duplo devolver o orçamento atualizado.

### D-39
**Adicionais no documento do cliente** (30/10/2026; substitui a D-16 na v2).

A prévia comercial (etapa 4), o PDF e os detalhes mostram, nesta ordem:
- os produtos, com quantidade, preço unitário e total;
- o total dos produtos;
- cada adicional maior que zero numa linha própria: insumos, impostos,
  combustível e outros (com a descrição);
- o subtotal, o desconto (se houver) e o total geral.

O custo das peças e dos materiais **não** vai para o documento do cliente;
aparece só no detalhe interno das peças (prompt §4). A mensagem do WhatsApp
continua só com o total geral.

### D-40
**Material em uso não troca de unidade** (revisão do plano da V2-C,
30/10/2026).

- `MaterialRepository.estaEmUso(id)` diz se alguma peça de orçamento salvo
  copiou o material (`pecas_orcamento.material_origem_id`). O SQLite
  consulta a tabela direto, sem a feature de materiais importar a de
  orçamentos. A tela usa o `materialEmUsoProvider(id)`.
- Num material em uso, a troca de unidade é **bloqueada**: o formulário
  explica que é preciso cadastrar um material novo e inativar o atual
  (prompt §3.1). Num material sem uso, a troca é livre.
- Os orçamentos salvos não mudam em nenhum caso, porque guardam a cópia do
  material (D-26).

### D-41
**Agenda da v2** (HO-V2-E-02, revisão do plano da V2-E, 30/10/2026).

- **"Agendar"** a partir de um orçamento abre uma tarefa nova vinculada,
  com o tipo Produção e o título "Produção <código>". Usa o `codigo`, sem
  a revisão, porque a tarefa se liga ao orçamento. O título acompanha a
  troca de tipo até o operador editá-lo. Com o orçamento excluído, o título
  vem vazio.
- **Tarefas do orçamento** (nos detalhes): pendentes primeiro, depois as
  concluídas, cada grupo em ordem cronológica. Sem tarefas, "Nenhuma
  tarefa agendada.". A seção "Agenda" que as envolve é dos detalhes.
- **Atrasada:** tarefa pendente de um dia anterior ao de hoje
  (`agoraProvider`). Uma tarefa de hoje com a hora já passada não está
  atrasada.
- **Aviso de atrasadas:** no topo da agenda, conta todas, sem considerar
  os filtros de tipo. "Ver" abre uma folha com a lista, e tocar numa
  tarefa leva ao dia dela.
- **Destaque:** faixa e marcador na cor de erro e a etiqueta "ATRASADA" no
  lugar da etiqueta do tipo, na agenda e nas tarefas do orçamento.

### D-42
**Acabamento da v2** (HO-V2-G-01, revisão do plano da V2-G, 31/10/2026).

- **Diálogos:** o `AppTheme` usa `dialogTheme.backgroundColor = surface`.
  O fundo padrão (`surfaceContainerHigh`) dava 4,41:1 ao `TextButton` em
  `primary`; em `surface`, dá 4,64:1 no claro e 5,18:1 no escuro (D-25).
  Os botões neutros ("Cancelar", "Entendi") ficam no laranja do tema, e a
  ação destrutiva, na cor de erro. Nenhum diálogo tem cor própria nos
  botões.
- **Confirmação:** toda confirmação usa o `confirmarAcao` de
  `core/widgets/confirmar_acao.dart`.
- **`TimelineTile`:** com a linha abaixo de 440 dp (celulares), a
  etiqueta ("PRODUÇÃO", "ATRASADA") fica acima do título; no tablet, ao
  lado.
- **`Dinheiro.formatado`** formata a partir dos centavos em `int`
  (`formatarCentesimosPtBr`), sem `double` (D-26). Não há outro
  formatador de moeda no app.
- **Etapa 2:** os campos de dinheiro da peça continuam com o `CampoTexto`
  decimal da feature (rótulo dentro da caixa, sufixo e ajuda); o
  `CampoDinheiro` do core serve aos formulários com o rótulo acima.

### D-43
**Ajustes depois da v2** (pedido do responsável, 03/11/2026).

- **Excluir orçamento:** além do menu dos detalhes, cada cartão da lista
  tem um menu com "Excluir". Os dois usam o `excluirOrcamento`, com a mesma
  confirmação e as mesmas regras (D-30, D-38).
- **Agenda:** os chips "Por dia" e "Todas" ficam acima da linha do tempo.
  "Todas" mostra todas as tarefas dos tipos marcados, inclusive as
  concluídas e as passadas, agrupadas por dia em ordem cronológica. Escolher
  um dia no calendário ou numa tarefa atrasada volta para "Por dia".
- **Materiais:** os chips são Ativos (padrão), Inativos e Todos.
- **Indicadores do início:** o ícone fica na linha do rótulo e o valor usa a
  largura toda do card, numa linha. Os quatro valores têm sempre o mesmo
  tamanho: o maior, até 32, em que o valor mais longo cabe.
- **Barra de navegação do sistema:** nenhuma tela fica por baixo dela. A
  raiz do app (`FeraApp`) reserva o espaço e pinta a área com o fundo do
  app, no claro e no escuro.
- **WhatsApp:** "Enviar WhatsApp" manda o PDF, em vez da mensagem pelo
  `wa.me`, que não aceita anexo. No Android, o `MainActivity` abre a conversa
  do cliente com o arquivo anexado (extra `jid`, que não é API oficial do
  WhatsApp); quem envia é o operador. Se não abrir (número inválido, iPhone
  ou WhatsApp que recuse), abre o compartilhamento do sistema. O texto que
  acompanha só tem a saudação, o código e o emitente: os valores ficam no
  PDF (D-39). O status passa a `enviado` ao abrir, porque o app não sabe se
  o operador enviou mesmo. O `url_launcher` saiu das dependências.
- **Sino:** saiu da `AppTopBar`, porque não tinha função (D-19). O app não
  tem notificações.

