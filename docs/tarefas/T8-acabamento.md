---
trilha: T8
titulo: Acabamento
status: pendente        # pendente | em andamento | em revisão | concluída
responsavel: —
branch: feat/t8-acabamento
depende_de: T2, T3, T4, T5, T6, T7
---

# T8: Acabamento

Única trilha que pode tocar em qualquer arquivo, porque roda sozinha, depois
de todas as outras.

## Checklist
- [ ] Revisar cada tela contra o PDF em `Teste/`, em modo claro e escuro e
      em telas pequenas (360 dp) e grandes.
- [ ] Revisar RF-01 a RF-86 e RNF-01 a RNF-06, um por um, e marcar no PR o
      que foi conferido.
- [ ] Unificar widgets parecidos que as trilhas criaram em paralelo; o que
      for usado em mais de uma feature vai para `core/widgets/`.
- [ ] Acessibilidade: `tooltip`/`semanticLabel` nos ícones de ação, áreas
      de toque de 48 dp, contraste dos chips.
- [ ] Ícone do app e splash com o logo FERA (Android e iOS), nome do app
      "FERA".
- [ ] `pubspec.yaml`: trocar `description` ("A new Flutter project.").
- [ ] `README.md` raiz: remover o aviso "Este commit contém apenas a
      estrutura base…" e descrever o que o app faz hoje.
- [ ] Levantar os `TODO(cliente)` restantes numa lista para levar ao
      cliente (D-04, D-07, D-08).

## Critério de aceite
Build de release Android e iOS sem erros, CI verde e todos os RF conferidos.
