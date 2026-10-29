---
trilha: V2-F1
titulo: Domínio e cálculo do orçamento por peças
status: em revisão     # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/v2-f1-dominio
depende_de: —
---

# V2-F1: domínio e cálculo

**Base:** prompt v2 §2, §3, §5, §6, §7 e §9
([`prompt-modulo-orcamento-v2.md`](../../prompt-modulo-orcamento-v2.md)).
**Decisões:** D-26, D-28, D-29, D-30 e D-33 em
[`02-decisoes.md`](../../02-decisoes.md), que valem sobre o prompt.
**Arquivos:** só arquivos **novos**, listados na
[`orquestracao.md` §3](../../orquestracao.md#3-o-que-cada-trilha-possui).

Código puro, sem tela, sem I/O e sem dependência nova. O modelo antigo
continua funcionando: as telas atuais não mudam nesta trilha. Os tipos que
têm o mesmo nome dos antigos (`Orcamento`, `ItemOrcamento`,
`StatusOrcamento`) ficam em `orcamentos/domain/v2/`. A F2 os move para o
lugar definitivo quando apagar os antigos.

Nenhum barrel existente é alterado. Os barrels novos (`materiais.dart`,
`empresa.dart`, `clientes.dart`) exportam só o `domain/` da própria
feature. Os arquivos de `v2/` importam esses barrels e os objetos de valor
de `core/domain/`.

## Checklist

### Objetos de valor (`lib/core/domain/`)
- [x] `Dinheiro`: centavos em `int`; somar, subtrair, comparar, multiplicar
      por inteiro, `zero`; formatação pt-BR (reaproveite o `formatarMoeda`
      de `core/utils/currency_format.dart`, sem duplicar); leitura de texto
      pt-BR ("1.234,56", "1234,5", "R$ 10") **sem passar por `double`**,
      rejeitando mais de duas casas. JSON: `int`.
- [x] `MedidaCm`: centésimos de cm em `int`, maior que zero quando exigida.
      Leitura de texto pt-BR com até duas casas; exibição pt-BR ("75",
      "7,5", "0,25"). Vazio é diferente de zero (prompt §6, "Entrada").
      JSON: `int`.
- [x] `Consumo`: valor exato em escala fixa de 12 casas (`BigInt`), com a
      unidade (`m²` ou `m³`), soma de consumos da mesma unidade e
      exibição pt-BR sem zeros à direita, com até 12 casas. JSON: texto
      canônico (ex: `"0.004800000000"`).
- [x] `Documento`: tipo CPF/CNPJ deduzido pela quantidade de dígitos (D-23),
      valor normalizado (só dígitos) e validação dos dígitos verificadores.
      Reaproveite `somenteDigitos` e os validadores de
      `core/utils/validators.dart`, sem duplicar. Formatação com máscara.
- [x] `Endereco`: `logradouro`, `numero` (texto, aceita "s/n"), `bairro`,
      `cidade`, `uf`, `cep?`, `complemento?`; `formatado` em uma linha.
- [x] Todos `freezed` + `json_serializable`, com conversores JSON quando o
      tipo não for nativo.

### Cadastros (domínio apenas)
- [x] `features/materiais/domain/`: `UnidadeCobranca` (`m2`, `m3`, serializada
      pelo nome), `Material` (`id`, `nome`, `unidade`, `precoReferencia`,
      `ativo = true`) e `MaterialRepository`, o contrato do prompt §7:
      `listarAtivos(filtro)`, `listarTodos()`, `buscarPorId`, `salvar`,
      `inativar` e `reativar`. Em `MaterialSnapshot`, `gerarSnapshot()`.
- [x] `features/empresa/domain/`: `Empresa` (`id`, `nomeRazaoSocial`,
      `documento`, `telefone`, `endereco`, `email?`), `estaCompleta`,
      `gerarSnapshot()` e `EmpresaRepository` (`obter`, `salvar`).
- [x] `features/clientes/domain/`: `Cliente` (`id`, `nome`, `documento`,
      `celular`, `endereco`), `gerarSnapshot()` e `ClienteRepository`
      (`buscarPorDocumento`, `pesquisar(termo)` por nome, celular ou
      documento, `salvar`).

### Orçamento (`lib/features/orcamentos/domain/v2/`)
- [x] Snapshots: `MaterialSnapshot` (`materialOrigemId?`, `nome`,
      `unidade`, `precoReferenciaCopiado`, `precoAplicado`, getter
      `precoAjustado`), `ClienteSnapshot` e `EmpresaSnapshot` (cópias
      completas com `...OrigemId?`).
- [x] `PecaOrcamento`: `id`, `descricao`, `quantidadePorProduto` (≥ 1),
      `material`, `comprimentoCm`, `larguraCm`, `espessuraCm?` (obrigatória
      em m³, informativa em m²), `observacoes?`; `duplicar(novoId)`.
- [x] `ItemOrcamento`: `id`, `descricao`, `quantidadeProdutos` (≥ 1),
      `precoBase`, `pecas` (≥ 1), `observacoes?`;
      `duplicarComNovosIds(gerarId)`, uma cópia profunda que recebe o
      gerador de ids.
- [x] `StatusOrcamento`: `criado` e `enviado` (D-29).
- [x] `Orcamento` (D-26 e D-30):
  - identificação: `id`, `codigo`, `revisao` (≥ 1), `chaveFinalizacao`;
  - datas: `criadoEm`, `atualizadoEm`;
  - `status`, `cliente` (`ClienteSnapshot`), `emitente`
    (`EmpresaSnapshot`), `itens`;
  - adicionais: `insumos`, `impostos`, `combustivel`, `outros`,
    `outrosDescricao?`, `desconto`;
  - `validadeDias?`, `observacoes?`;
  - `totais` (`ResultadoOrcamento`) e `versaoCalculo`;
  - getters: `dataValidade?` (a partir de `atualizadoEm`), `codigoExibicao`
    (`281026-03`, ou `281026-03 rev. 2` a partir da 2ª revisão) e
    `totalGeral`.
- [x] `OrcamentoEmEdicao`: a sessão em memória do prompt §7. Inclui
      `orcamentoOrigemId?`, `codigo?` e `revisao?` quando é a edição de um
      salvo (D-30). Sem `totais` gravados.
- [x] Resultados: `ResultadoPeca`, `ResultadoItem` e `ResultadoOrcamento`
      (prompt §7), com JSON, porque os totais ficam gravados no orçamento.
- [x] `CalculadoraOrcamento` (`versaoCalculo = 1`): `calcularPeca`,
      `calcularItem`, `calcularOrcamento`. Pura e determinística, sem
      relógio nem cadastro. Rejeita total negativo. Arredondamento half-up
      só no custo unitário da peça (prompt §5).
- [x] Validação: `ErroValidacao` (`caminhoCampo`, `codigo`, `mensagem`) e
      funções ou serviço com `validarDocumento`, `validarCliente`,
      `validarEmpresa`, `validarMaterial`, `validarPeca`, `validarItem` e
      `validarOrcamento`, com as regras do prompt §6. O caminho segue o
      formato `itens[0].pecas[1].espessuraCm`.
- [x] `codigo_orcamento.dart`: `formatarCodigoOrcamento(DateTime data, int
      sequenciaDoDia)` → `AAMMDD-NN` (D-30), mais a leitura do código de
      volta para data e sequência.
- [x] Contratos de persistência, só as interfaces:
  - `OrcamentoRepository` v2: `listarResumos`, `buscarPorId`,
    `buscarPorChaveFinalizacao`, `inserir`, `atualizar` e `excluir`;
  - `SequenciaRepository`: `proximaDoDia(DateTime)`;
  - `UnidadeDeTrabalho`: `executarEmTransacao`.

  A F2 implementa com SQLite. O serviço de finalização também é da F2.

### Documentação
- [x] Em `CLAUDE.md` e `.cursorrules` (iguais): reescrever a seção "Domínio
      do negócio" com o modelo v2, apontando a D-26 a D-30.
  - O modelo antigo e o catálogo aparecem como "em substituição na rodada
    v2 (F2)".
  - "Sobre o app" e a estrutura de pastas passam a citar SQLite (D-27),
    `core/domain/` e as features `materiais`, `empresa` e `clientes`.
  - Não mude outras seções.

## Testes (`test/unit/v2/`)
- [x] Todos os cenários da seção 9 do prompt, com os valores exatos:
  - A, B e C;
  - modelo antigo em m³ e medidas diferentes em linhas separadas;
  - precisão (R$ 0,01 por peça, R$ 0,03 em três);
  - mudança de preço no cadastro e preço ajustado só na peça;
  - troca de unidade;
  - duplicação independente.
- [x] `Dinheiro` e `MedidaCm`: leitura pt-BR válida e inválida, limites,
      half-up e ausência de `double` no caminho do cálculo.
- [x] `Documento`: CPF e CNPJ válidos e inválidos, e máscara.
- [x] Validação: cada regra do prompt §6 gera o `ErroValidacao` com o
      caminho certo; desconto maior que o subtotal; "outros" sem descrição;
      total zero sinalizado.
- [x] JSON de ida e volta de `Orcamento` completo (com resultados e
      consumo em texto).
- [x] Código `AAMMDD-NN`: formatação, sequência acima de 99 e leitura.

## Critério de aceite
`flutter test test/unit/v2` cobre os exemplos A, B e C do prompt e dá
R$ 2.706,40, R$ 644,40 e R$ 3.630,80. O app continua abrindo e funcionando
como antes, com os 380 testes antigos passando.
