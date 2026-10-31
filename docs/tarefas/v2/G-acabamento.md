---
trilha: V2-G
titulo: Acabamento da rodada v2
status: concluída     # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/v2-g-acabamento
depende_de: V2-A, V2-B, V2-C, V2-D, V2-E
---

# V2-G: acabamento

**Arquivos:** qualquer arquivo (roda sozinha, por último).
**Decisões:** D-26 a D-41. Os pedidos que as trilhas deixaram para esta
fase estão nos handoffs `docs/handoffs/v2/{A,B,C,D,E}.md` e no registro da
[`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

Não muda regra de negócio nem cálculo. Junta o que ficou duplicado entre as
trilhas, fecha a acessibilidade e a documentação e prepara a entrega.

## Checklist

### Telas e acessibilidade
- [x] O `telas_pequenas_test` cobre todas as telas novas: 360 dp, 412 dp e
      tablet; claro e escuro; contraste (D-25); toque de 48 dp; rótulos.
      Inclui o formulário de material e a empresa com os erros visíveis,
      que a V2-C não conseguiu cobrir por lá (HO-V2-C-01).
- [x] Contraste do `TextButton` padrão nos diálogos: corrigir no
      `AppTheme` (HO-V2-B-04) e tirar as cores próprias que A, B e C
      puseram nos diálogos, se ficarem redundantes.
- [x] O título do cartão do `TimelineTile` quebra demais a 360 dp
      (HO-V2-E-03): ajustar no core, sem mudar a assinatura.

### Duplicações entre as trilhas (regra 1 do `CLAUDE.md`)
- [x] `confirmarAcao` (`wizard/wizard_dialogos.dart`) vai para
      `core/widgets/`, e os diálogos de confirmação da C, da D e da E
      passam a usá-lo (HO-V2-C-02).
- [x] Os widgets genéricos da V2-A em `wizard/produto/` (`CampoTexto`,
      `AvisoInline`, `LinhaResumo`, `MenuAcoesLinha`): comparar com o core
      (`FormCampo`, `CampoDinheiro`, a `LinhaValor` da prévia) e juntar o
      que for igual. Os campos de dinheiro da etapa 2 podem usar o
      `CampoDinheiro` se ele ganhar um `controller` opcional (o preço da
      peça é preenchido pelo app ao escolher o material).
- [x] Helpers de teste: um `abrirWizard` em `wizard_teste_helpers.dart` no
      lugar dos `abrir` repetidos (HO-V2-B-04) e os helpers da C em
      `test/widget/core/` se servirem a outras telas. Atualizar o doc de
      `preencherStub`, que ainda fala em "wizard em stub".
- [x] `Dinheiro.formatado` e `formatadoSemSimbolo` passam por `double` para
      exibir (HO-V2-A-03): formatar a partir dos centavos em `int`, com
      teste de valor grande.

### Fluxo de ponta a ponta
- [x] Um teste de widget com o fluxo completo:
  - cadastrar a empresa e os materiais;
  - montar os exemplos A e B;
  - finalizar;
  - editar (rev. 2);
  - enviar;
  - agendar.
- [x] Conferir os cenários da seção 9 do prompt pela interface.
      *(A, B e C no app rodando no Windows e no teste de ponta a ponta;
      os demais pelos testes de widget e unitários, ver o relatório.)*

### Documentação e entrega
- [x] Atualizar o README, `01-requisitos.md` (requisitos da v2, sem o
      `CurrencyField` e o catálogo), `04-plano.md` e a lista de perguntas
      ao cliente. A lista perde margem, prazo, validade, emissor,
      rascunho, custo zero e fotos, já resolvidos, e ganha o que ficou
      aberto (ex: custos de material no PDF).
- [x] `CLAUDE.md` e `.cursorrules` iguais e atualizados (quebrar a linha
      longa do `MaterialRepository`).
- [x] Gerar o APK de release e testar no Windows (`flutter run -d windows`),
      com um banco novo e com os exemplos.
