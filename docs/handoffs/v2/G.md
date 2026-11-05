# Handoff V2-G

Pedidos e dúvidas da trilha V2-G ([`tarefas/v2/G-acabamento.md`](../../tarefas/v2/G-acabamento.md)).
Editado só pela própria trilha, na branch `feat/v2-g-acabamento`. Formato e regras em
[`orquestracao.md` §6](../../orquestracao.md#6-handoffs); as respostas do
orquestrador ficam em [`orquestracao.md` §10](../../orquestracao.md#10-registro-de-handoffs).

Caminhos relativos a `fera_metalurgica_app/`.

## Pedidos

### HO-V2-G-01: escolhas da V2-G para registrar num D-xx
- **Tipo:** decisão (aprovadas pelo responsável na revisão do plano)
- **Arquivo(s):** `docs/02-decisoes.md` (do orquestrador)
- **O quê:**
  1. **Fundo dos diálogos** (HO-V2-B-04): o `AppTheme` usa
     `dialogTheme.backgroundColor = surface`, sem token novo e sem
     `textButtonTheme` global. O fundo padrão (`surfaceContainerHigh`) caía
     em `background`, onde o `TextButton` em `primary` dava 4,41:1 no
     claro. Agora:
     - claro: `primary` 4,64:1, `error` 6,46:1;
     - escuro: `primary` 5,18:1, `error` 10,09:1.

     Mudança visível: **"Cancelar" (`confirmarAcao`) e "Entendi" (aviso
     de unidade em uso do material) passam de preto/branco para o laranja
     do tema.** A ação destrutiva continua em `error`. Nenhum diálogo ficou
     abaixo de 4,5:1.
  2. **`confirmarAcao` no core** (`core/widgets/confirmar_acao.dart`),
     usado pelo wizard (A, B), pelos detalhes (D), por "Inativar material?"
     (C) e por "Excluir tarefa?" (E). O "Excluir" da tarefa passa a
     aparecer na cor de erro, como as outras ações destrutivas.
  3. **`TimelineTile`** (HO-V2-E-03): com a linha do tile abaixo de 440 dp
     (360 e 412 dp), a etiqueta ("PRODUÇÃO", "ATRASADA") vai para cima do
     título; no tablet, fica ao lado, como antes. A assinatura não mudou.
  4. **`Dinheiro.formatado`** formata a partir dos centavos em `int`
     (`formatarCentesimosPtBr` em `core/domain/decimal_pt_br.dart`). Saiu o
     `core/utils/currency_format.dart` (`formatarMoeda` em `double`), que só
     o `Dinheiro` usava.
- **Por quê:** D-25 (contraste), D-26 (sem `double`), regra 1 do
  `CLAUDE.md` (sem duplicação).
- **Enquanto isso:** aplicado e testado na branch.

### HO-V2-G-02: o que foi juntado e o que ficou separado (regra 1)
- **Tipo:** registro
- **O quê:**
  - **Juntados:**
    - `confirmarAcao` → `core/widgets/` (ver HO-V2-G-01);
    - os três avisos do wizard (`AvisoInline` da V2-A, `AvisoTotalZero` e
      o aviso de documento da etapa 1, da V2-B) → um
      `wizard/aviso_inline.dart`, com o ícone e a ação como parâmetros. Fica
      na feature `orcamentos`, porque nenhuma outra o usa (03-padroes §1).
      O `AvisoAtrasadas` da agenda não entrou: tom de erro e layout
      próprios;
    - helpers de teste: `test/widget/materiais/materiais_teste_helpers.dart`
      virou `test/widget/core/teste_helpers.dart` (`abrirEm`, `tocar` e
      `digitar` com rolagem, `conferirAcessibilidade`); o
      `wizard_teste_helpers.dart` reexporta esse `tocar` e ganhou o
      `abrirWizard`, que substitui o router repetido em três testes da B.
  - **Ficaram separados, com motivo:**
    - **`CampoTexto` (etapa 2) × `CampoDinheiro`:** o `CampoDinheiro` tem o
      rótulo acima do campo (`FormCampo`); os campos da etapa 2 têm o
      rótulo dentro da caixa, e o preço da peça precisa de sufixo ("/m²"),
      ajuda e erro de regra. Usar o `CampoDinheiro` ali misturaria dois
      estilos no mesmo formulário e pediria `controller`, sufixo e ajuda
      novos. Mantido o `CampoTexto` decimal, com OK do responsável;
    - **`LinhaResumo` × `LinhaValor`:** hierarquias diferentes (destaque
      em `bodyStrong` × `title`, valor em w600). Juntar mudaria a tela;
    - **`MenuAcoesLinha`:** não há equivalente; os menus da C e da D têm
      outras ações.
- **Enquanto isso:** nada.

### HO-V2-G-03: as tarefas do orçamento também espremem o título a 360 dp
- **Tipo:** aviso (fora do checklist da V2-G; não mexi)
- **Arquivo(s):** `lib/features/cronograma/presentation/orcamento/`
  (`TarefasDoOrcamento`)
- **O quê:** nos detalhes do orçamento, a 360 dp, o widget de tarefas do
  orçamento (que não usa o `TimelineTile`) põe a etiqueta ao lado do
  título: "Revisar orçamento 291026-01" ocupa 3 linhas no app rodando no
  Windows (captura do exemplo C). É o mesmo problema do HO-V2-E-03.
- **Sugestão:** a mesma regra do `TimelineTile` (etiqueta acima do título
  quando estreito), numa trilha futura.
- **Enquanto isso:** o texto não transborda e passa no
  `telas_pequenas_test`; só quebra mais do que precisa.

### HO-V2-G-04: avisos
- **Tipo:** aviso
- **O quê:**
  - **Caminhos que mudaram** (para a tabela da `orquestracao.md` §3 e
    quem consultar a posse da v2):
    - `wizard/wizard_dialogos.dart` → `core/widgets/confirmar_acao.dart`;
    - `wizard/produto/aviso_inline.dart` → `wizard/aviso_inline.dart`;
    - `test/widget/materiais/materiais_teste_helpers.dart` →
      `test/widget/core/teste_helpers.dart`;
    - `test/widget/cronograma/tarefas_atrasadas_test.dart` →
      `test/unit/tarefas_atrasadas_test.dart` (sem mudar o conteúdo).
  - **Documentos históricos** (`historico/`, tarefas T3 e T8, handoff e
    prompt da F1) ainda citam `formatarMoeda` e `wizard_dialogos.dart`. Não
    alterei: são registro do que foi feito.
  - **`TimelineTile` reproduzido antes de mexer:** teste provisório (fora
    do commit) com a agenda real a 360 dp, a fonte Inter do projeto
    carregada como "Roboto" (mais larga que a Roboto, então pessimista) e
    tarefas com "PRODUÇÃO" e "ATRASADA". Antes: título com 79 dp de
    largura, "Produção 281026-03" em 3 linhas, um título de 59 letras em 9,
    e "Revisar orçamento 261026-01" quebrado no meio das palavras. Depois:
    172 dp, 2, 2 e 4 linhas. No app real (Windows, Segoe UI), "Revisar
    orçamento 291026-01" ficou em 2 linhas.
  - **Ambiente:** o `flutter doctor` acusa licenças do Android não
    aceitas, mas o `flutter build apk --release` funcionou. Não aceitei
    nem instalei nada.
- **Enquanto isso:** nada.
