---
trilha: T5
titulo: PDF e WhatsApp
status: em andamento  # pendente | em andamento | em revisão | concluída
responsavel: Claude (agente T5)
branch: feat/t5-pdf-whatsapp
depende_de: T2
---

# T5: Prévia do PDF e envio por WhatsApp (Tela 7 + ações da Tela 6)

**Requisitos:** RF-34, RF-40 a RF-42.
**Decisões:** D-01, D-04, D-06, D-09, D-15, D-16.
**Arquivos:** `orcamentos/data/pdf/**`, `orcamentos/data/whatsapp/**`,
`orcamentos/domain/mensagem_whatsapp.dart`, `orcamentos/presentation/pdf/**`,
os testes correspondentes e, **em `detalhes/`, apenas** o método
`_enviarWhatsApp` deixado pela T2.

> `domain/` e `data/` são congelados após a F1, mas estes caminhos são
> arquivos **novos** reservados à T5 no [`04-plano.md`](../04-plano.md). Para
> expô-los fora da feature, não edite o barrel: a página do PDF e os
> detalhes já estão dentro da feature e importam o caminho relativo.

## Checklist

### PDF
- [ ] `data/pdf/orcamento_pdf_builder.dart`: `Future<Uint8List>
      gerarOrcamentoPdf(Orcamento)` com o pacote `pdf`. Layout da Tela 7:
      logo (`assets/images/logo_fera.png`), "ORÇAMENTO", "Nº 00482", data,
      validade, EMISSOR (`AppConstants`), CLIENTE, tabela "Descrição do item
      / serviço | Qtd" e "Valor Total". Nada de custos internos.
- [ ] `presentation/pdf/orcamento_pdf_page.dart`: `PdfPreview` (pacote
      `printing`) sem as ações padrão, mais o rodapé Voltar/"Baixar". Baixar
      chama `Printing.sharePdf(bytes, filename: 'orcamento-<id>.pdf')`.

### WhatsApp
- [ ] `domain/mensagem_whatsapp.dart`: função pura `String
      montarMensagemWhatsApp(Orcamento)` (D-15).
- [ ] `data/whatsapp/whatsapp_launcher.dart`: `Future<bool>
      abrirWhatsApp(String numero, String mensagem)` com `url_launcher`,
      exposto por um provider `@riverpod` (para poder trocar por mock nos
      testes).
- [ ] Em `detalhes/`: implementar `_enviarWhatsApp`. Se abrir com sucesso e o
      status for `emAnalise`, salvar como `enviado` (D-06). Se falhar,
      mostrar `SnackBar`.

## Testes
- [ ] Unitário: `montarMensagemWhatsApp` (sem custos; com número, valor,
      prazo e validade); `gerarOrcamentoPdf` retorna bytes não vazios para o
      seed.
- [ ] Widget: o botão WhatsApp com launcher mockado (sucesso muda o status;
      falha mostra o SnackBar), em
      `test/widget/orcamentos/detalhes/enviar_whatsapp_test.dart` (os demais
      testes de `detalhes/` são da T2), e a prévia em
      `test/widget/orcamentos/pdf/`.

## Critério de aceite
Nos detalhes do #00482: "Gerar PDF" mostra a prévia e "Baixar" abre o
compartilhamento; "Enviar WhatsApp" abre a conversa e o chip vira
"Enviado".
