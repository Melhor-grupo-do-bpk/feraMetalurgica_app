# Planejamento do FERA

Esta pasta é a fonte única do **o quê** e do **quando** do desenvolvimento.
O **como** (estrutura de pastas, lint, freezed, riverpod, cores) continua em
[`../CLAUDE.md`](../CLAUDE.md), espelhado em `.cursorrules`. Os dois se
complementam: se algo aqui parecer contradizer o `CLAUDE.md`, pare e pergunte.

Toda pessoa ou IA (Claude Code, Cursor, Copilot, Codex…) que for trabalhar no
app lê, nesta ordem:

1. [`../CLAUDE.md`](../CLAUDE.md): regras estruturais, não negociáveis.
2. [`02-decisoes.md`](02-decisoes.md): como resolvemos cada ambiguidade entre
   as telas do Figma e o modelo de dados. **Decisão registrada aqui vale mais
   que a imagem do Figma.**
3. [`03-padroes.md`](03-padroes.md): padrões de código das telas, providers,
   testes e git.
4. [`04-plano.md`](04-plano.md): fases, trilhas paralelas e a tabela de quais
   arquivos cada trilha pode tocar.
5. O arquivo da sua tarefa em [`tarefas/`](tarefas/).

[`01-requisitos.md`](01-requisitos.md) lista os requisitos de cada tela
(RF-xx). As telas originais estão em [`../Teste/`](../Teste/) (Tela 1 a 10).

## Como pegar uma tarefa

1. Abra [`04-plano.md`](04-plano.md) e escolha uma trilha com `status:
   pendente` cujas dependências estejam `concluída`.
2. No arquivo da trilha em `tarefas/`, mude `status` para `em andamento` e
   preencha `responsavel` (nome da pessoa e, se for o caso, a IA usada).
   Faça disso o primeiro commit da sua branch.
3. Trabalhe **só** nos arquivos que a trilha possui (seção "Arquivos" do
   arquivo da trilha). Precisa mexer em outro? Veja a seção "Mudanças fora da
   sua trilha" em [`04-plano.md`](04-plano.md).
4. Ao abrir o PR, mude o status para `em revisão`. Quem fizer o merge muda
   para `concluída`.

## Como registrar uma decisão nova

Encontrou algo que as telas não respondem? Não invente. Pergunte ao time e
registre a resposta como um novo `D-xx` no **fim** de
[`02-decisoes.md`](02-decisoes.md), no mesmo PR que a usa. Se outro PR criar o
mesmo número antes, renumere a sua ao resolver o conflito.
