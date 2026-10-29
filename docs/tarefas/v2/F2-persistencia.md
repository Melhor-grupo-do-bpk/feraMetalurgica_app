---
trilha: V2-F2
titulo: Persistência SQLite e troca do modelo no app
status: pendente     # pendente | em andamento | em revisão | concluída
responsavel: —
branch: feat/v2-f2-persistencia
depende_de: V2-F1
---

# V2-F2: persistência e troca do modelo

**Base:** prompt v2 §7 (repositórios e serviços), §8 e §11.
**Decisões:** D-26 a D-36. Contratos da F1: D-34 e o handoff
[`handoffs/v2/F1.md`](../../handoffs/v2/F1.md).
**Arquivos:** qualquer arquivo. A F2 roda sozinha, entre a F1 e as trilhas
paralelas.

Conecta o domínio da F1 ao app. Ao final, o modelo antigo, o catálogo e o
`LocalJsonStorage` não existem mais. O app compila e roda, e as telas que
as trilhas A a E vão construir aparecem como placeholders ou na versão
mínima descrita abaixo.

## Checklist

### Persistência (D-27)
- [ ] Dependências `sqflite` (app) e `sqflite_common_ffi` (dev; também usada
      no `main.dart` quando a plataforma for desktop, para rodar no
      Windows).
- [ ] Banco único, aberto por um provider em `core/di/`, com esquema
      versionado (`onCreate` e `onUpgrade`). Versão do esquema separada da
      `versaoCalculo`.
- [ ] Tabelas:
  - `materiais`, `empresa`, `clientes`, `tarefas`;
  - `orcamentos` (com `codigo`, `chave_finalizacao` e as cópias de cliente
    e emitente serializadas);
  - `itens_orcamento` e `pecas_orcamento` (com a ordem, e o material
    copiado em cada peça);
  - `sequencias` (contador por dia, D-30).
- [ ] Unicidade de `codigo`, `chave_finalizacao` e documento normalizado do
      cliente.
- [ ] Excluir um orçamento exclui os itens e as peças dele (cascata), nunca
      materiais nem clientes.
- [ ] Repositórios: os contratos da F1, mais `TarefaRepository` no SQLite.
      `UnidadeDeTrabalho` com transação real. Testes de cada repositório
      com `sqflite_common_ffi` em memória (regra 7 do `CLAUDE.md`).

### Serviços e estado
- [ ] Serviço de finalização com as dependências do prompt §7 (`Relogio` é
      o `agoraProvider`). Faz o algoritmo do prompt §8, mais a edição da
      D-30:
  - revalida e recalcula;
  - resolve o cliente pelo documento;
  - na criação: reserva o código do dia;
  - na edição: `revisao + 1`, `atualizadoEm` e, se estava `enviado`, volta
    para `criado`;
  - grava tudo em transação;
  - é idempotente pela `chaveFinalizacao`.
- [ ] Controller da edição (D-28): Notifier com o estado e as operações da
      D-28. `iniciar()` para novo e `iniciarEdicao(orcamentoId)` para
      editar. Sem fórmulas, que ficam na calculadora, e sem SQL, que fica
      nos repositórios.
- [ ] Providers de leitura para as telas: lista de orçamentos salvos (com
      os totais gravados), orçamento por id, materiais ativos e todos,
      empresa, busca de clientes e tarefas. Mantenha o padrão síncrono de
      `AsyncValue` usado hoje nas listas.

### Troca do modelo no app
- [ ] Mover os tipos de `orcamentos/domain/v2/` para `orcamentos/domain/`
      (com `git mv`) e apagar o modelo antigo: `CustosOperacionais`,
      `Medidas`, `calculo_orcamento.dart` e o `Cliente` do orçamento.
- [ ] Remover o catálogo (D-31): feature, rotas, seed, assets
      `assets/images/catalogo/`, testes e a entrada no `pubspec.yaml`.
- [ ] Navegação (D-31):
  - abas Início, Orçamentos, Agenda e Mais;
  - em "Mais": "Materiais" e "Dados da empresa";
  - rotas novas em `AppRoutes`: materiais, material (novo/editar), empresa
    e `tarefa(orcamentoId:)`;
  - um stub por tela nova.
- [ ] "Novo orçamento" bloqueado sem empresa completa (prompt §3.2): leva
      a "Dados da empresa".
- [ ] Telas existentes, o mínimo para compilar e mostrar o modelo novo, sem
      redesenhar (o acabamento é das trilhas):
  - lista: código, cliente, data, total e status;
  - detalhes: leitura;
  - dashboard: D-32;
  - PDF e WhatsApp: totais e cópias gravados; sem prazo; validade só se
    houver; emissor da cópia.
- [ ] Wizard: o antigo sai; as 4 etapas novas viram stubs ligados ao
      controller, com navegação entre etapas e "Finalizar" funcionando.
      O formulário completo é das trilhas A e B.
- [ ] Cronograma: tarefas no SQLite e vínculo pelo `id` do orçamento,
      exibindo o código. Stub do widget de tarefas do orçamento e do botão
      "Agendar" para a E implementar e a D posicionar.
- [ ] Exemplos em debug (D-17), gravados a partir de `agoraProvider`:
  - empresa de exemplo;
  - materiais granito (m²), madeira (m³) e MDF (m²);
  - os orçamentos A+B (cenário C) e B sozinho;
  - tarefas de hoje e de amanhã (HO-T8-01).
- [ ] Remover o `LocalJsonStorage`, o `InMemoryJsonStorage` e as constantes
      antigas de `AppConstants`.
- [ ] Testes: reescrever os que dependiam do modelo antigo. Adaptar o
      `feraAppDeTeste()` para SQLite em memória com os exemplos; o
      `app_router_test`, o `app_shell_test` e o `telas_pequenas_test`
      continuam passando.

### Documentação
- [ ] Em `03-padroes.md` §4, trocar `numeroFormatado` por `codigoExibicao`
      (HO-V2-F1-11).
- [ ] Atualizar `CLAUDE.md` e `.cursorrules`: tirar as marcas "em
      substituição", trocar `LocalJsonStorage` por SQLite e remover o
      catálogo.
- [ ] No handoff: a lista dos contratos expostos às trilhas A a E (providers,
      controller e rotas), para o orquestrador fechar a `orquestracao.md`
      §3 e §4.

## Critério de aceite
- Com os exemplos de debug, a lista mostra os dois orçamentos de exemplo
  com os totais certos (R$ 3.630,80 e R$ 644,40).
- O wizard em stub cria um orçamento novo com código `DDMMAA-01`; editar
  gera "rev. 2".
- A agenda abre com tarefas de hoje.
- `flutter analyze --fatal-infos` sem problemas e todos os testes passando.
