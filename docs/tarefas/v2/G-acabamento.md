---
trilha: V2-G
titulo: Acabamento da rodada v2
status: pendente     # pendente | em andamento | em revisão | concluída
responsavel: —
branch: feat/v2-g-acabamento
depende_de: V2-A, V2-B, V2-C, V2-D, V2-E
---

# V2-G: acabamento

**Arquivos:** qualquer arquivo (roda sozinha, por último).

## Checklist
- [ ] O `telas_pequenas_test` cobre todas as telas novas: 360 dp, 412 dp e
      tablet; claro e escuro; contraste (D-25); toque de 48 dp; rótulos.
- [ ] O fluxo completo, de ponta a ponta, num teste de widget:
  - cadastrar a empresa e os materiais;
  - montar os exemplos A e B;
  - finalizar;
  - editar (rev. 2);
  - enviar;
  - agendar.
- [ ] Conferir os cenários da seção 9 do prompt pela interface.
- [ ] Atualizar o README, `01-requisitos.md` (requisitos da v2), `04-plano.md`
      e a lista de perguntas ao cliente. Ela perde margem, prazo, validade,
      emissor, rascunho, custo zero e fotos, já resolvidos, e ganha o que
      ficou aberto (ex: custos de material no PDF).
- [ ] Gerar o APK de release e testar no Windows (`flutter run -d windows`).
