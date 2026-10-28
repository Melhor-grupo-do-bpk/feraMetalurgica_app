---
trilha: T8
titulo: Acabamento
status: em revisão         # pendente | em andamento | em revisão | concluída
responsavel: Felipe Drehmer (Claude Code, Opus 5.5)
branch: feat/t8-acabamento
depende_de: T2, T3, T4, T5, T6, T7
---

# T8: Acabamento

Única trilha que pode tocar em qualquer arquivo, porque roda sozinha, depois
de todas as outras.

## Checklist
- [x] Revisar cada tela contra o PDF em `Teste/`, em modo claro e escuro e
      em telas pequenas (360 dp) e grandes. Capturas em teste (Roboto do
      SDK) comparadas com as Telas 1 a 10; `telas_pequenas_test.dart`
      abre todas as rotas em 360 dp, 412 dp e tablet. Falta conferir em
      aparelho real.
- [x] Revisar RF-01 a RF-86 e RNF-01 a RNF-06, um por um (tabela abaixo).
- [x] Unificar widgets parecidos: `WizardCampo` virou `FormCampo` em
      `core/widgets/` (wizard e formulário de tarefa, HO-T7-02). Ficam
      onde estão, por serem de uma feature só (03-padroes §1): os cartões
      de orçamento da lista e do dashboard (layouts diferentes no Figma),
      a `CategoriaTag` (HO-T6-02) e a normalização da busca (HO-T2-02).
- [x] Acessibilidade: diretrizes de toque (48 dp), rótulo e contraste do
      Flutter em todas as telas, nas etapas 2 a 4 do wizard, na folha do
      produto e no diálogo de status; tokens ajustados (D-25).
- [x] Ícone do app e splash com o logo FERA (Android e iOS, D-24), nome do
      app "FERA".
- [x] `pubspec.yaml`: trocar `description`.
- [x] `README.md` raiz: descrição do que o app faz hoje.
- [x] Levantar os `TODO(cliente)` restantes:
      [`relatorios/2026-10-28-perguntas-cliente.md`](../relatorios/2026-10-28-perguntas-cliente.md).

Também feito: fonte Inter no PDF (HO-T5-01), tokens `whatsapp`/`onWhatsapp`
(HO-T2-01), `ItemCard` com 48 dp (HO-T3-03), comentário do `StatusTone`
(HO-T4-01), navegação inferior sem transbordar (relatório da T7) e app só
em retrato (RNF-01).

## Conferência de requisitos

✅ conferido (teste automático citado ou leitura do código) · ⚠️ com
ressalva.

| Req. | Situação | Onde |
|---|---|---|
| RF-01 | ✅ | `app_shell_test` (4 abas, pilha por aba) |
| RF-02 | ✅ | `app_router_test`; voltar só fora das raízes (`catalogo_page_test` "top bar sem voltar") |
| RF-03 | ✅ | `app_router_test` (telas cheias sem navegação inferior) |
| RF-10 | ✅ | `dashboard_page_test` "Criar orçamento" abre o wizard |
| RF-11 | ✅ | `dashboard_indicadores_test` (D-03, rascunho não conta) |
| RF-12 | ✅ | `dashboard_page_test` (2 recentes, sem rascunho, abre detalhes) |
| RF-13 | ✅ | `dashboard_page_test` "Ver todos" |
| RF-14 | ✅ | `dashboard_indicadores_test` (salvar orçamento ou concluir tarefa atualiza) |
| RF-20 | ✅ | `orcamento_wizard_page_test` (voltar mantém dados, voltar do sistema, "Descartar orçamento?") |
| RF-21 | ✅ | idem (máscaras, CPF/CNPJ, e-mail) |
| RF-22 | ✅ | idem (projeto, item do catálogo/"Outro", editar e excluir, mínimo 1 item) |
| RF-23 | ✅ | idem (total atualizado ao digitar) |
| RF-24 | ✅ | idem (resumo e `pushReplacement` para os detalhes) |
| RF-25 | ✅ | idem (`emAnalise` e próximo número) |
| RF-26 | ✅ | idem (edição preserva id, data e status) |
| RF-27 | ✅ | idem (`?produtoId=` cria o 1º item) |
| RF-30 | ✅ | `orcamento_detalhes_page_test` |
| RF-31 | ✅ | idem (sem valor por item, D-01) |
| RF-32 | ✅ | idem; botão WhatsApp com os tokens novos |
| RF-33 | ✅ | idem ("Alterar status") |
| RF-34 | ✅ | `enviar_whatsapp_test` (`emAnalise` → `enviado`) |
| RF-40 | ✅ | `orcamento_pdf_builder_test`; PDF rasterizado e comparado com a Tela 7 |
| RF-41 | ✅ | o gerador do PDF não lê `custosOperacionais` |
| RF-42 | ✅ | `orcamento_pdf_page_test` (`orcamento-00482.pdf`) |
| RF-50 | ✅ | `orcamentos_lista_page_test` ("Novo" abre o wizard) |
| RF-51 | ✅ | `filtrar_orcamentos_test` (acentos, número) |
| RF-52 | ✅ | `orcamentos_lista_page_test` (chips de D-22 na ordem) |
| RF-53 | ✅ | idem ("Valor Estimado" no rascunho) |
| RF-54 | ✅ | `orcamentos_controller_test` (mais recente primeiro); estado vazio com "Novo" |
| RF-60 | ✅ | `catalogo_page_test` (chips em ordem alfabética) |
| RF-61 | ✅ | idem (foto, placeholder) |
| RF-62 | ✅ | idem (folha e "Usar no orçamento") |
| RF-70 | ✅ | `app_router_test` (`/mais`, `/mais/cronograma`) |
| RF-80 | ✅ | `cronograma_page_test`, `calendario_mes_test` |
| RF-81 | ✅ | `cronograma_page_test` (3 filtros) |
| RF-82 | ✅ | idem (atalhos de dia) |
| RF-83 | ✅ | idem (seções "Hoje"/"Amanhã") |
| RF-84 | ✅ | `cronograma_page_test` (círculo conclui), `timeline_tile_test` (riscada) |
| RF-85 | ✅ | idem ("Ver Detalhes") |
| RF-86 | ✅ | `tarefa_form_page_test` (validação, edição e exclusão) |
| RNF-01 | ⚠️ | claro/escuro e 360 dp a tablet em `telas_pequenas_test`; retrato travado no Android e no iPhone (o iPad gira, exigência da App Store). Falta aparelho real. |
| RNF-02 | ✅ | I/O só em `data/` (`LocalJsonStorage`) |
| RNF-03 | ✅ | `flutter analyze --fatal-infos` e `flutter test` verdes |
| RNF-04 | ✅ | `formatarMoeda`/`formatarData`, `flutter_localizations` pt-BR |
| RNF-05 | ✅ | carregando/vazio/erro nas telas com dados assíncronos ("Tentar novamente") |
| RNF-06 | ✅ | `androidTapTargetGuideline`, `labeledTapTargetGuideline` e `textContrastGuideline` em `telas_pequenas_test` |

## Critério de aceite
Build de release Android e iOS sem erros, CI verde e todos os RF conferidos.

- Android: ver o resultado de `flutter build apk --release` no relatório
  da T8.
- iOS: pendente (precisa de um Mac).
