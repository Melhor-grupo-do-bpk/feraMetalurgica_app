import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String _logoAsset = 'assets/images/logo_fera.png';

/// Fonte do PDF (Inter, a do Figma, licença OFL em `assets/fonts/OFL.txt`).
/// A fonte padrão do pacote `pdf` só desenha Latin-1; com a Inter, aspas
/// curvas, travessões e o "•" de D-01 saem como foram digitados.
const String fontePdfRegular = 'assets/fonts/Inter-Regular.ttf';

/// Versão em negrito de [fontePdfRegular].
const String fontePdfNegrito = 'assets/fonts/Inter-Bold.ttf';

Future<pw.Font> _carregarFonte(String asset) async =>
    pw.Font.ttf(await rootBundle.load(asset));

/// Uma linha de produto no PDF: descrição, observações, quantidade, preço
/// unitário e total, já formatados.
typedef LinhaProdutoPdf = ({
  String descricao,
  String? observacoes,
  String quantidade,
  String precoUnitario,
  String total,
});

/// Uma linha dos totais no PDF: rótulo e valor formatado; `destaque` só no
/// total geral.
typedef LinhaTotalPdf = ({String rotulo, String valor, bool destaque});

/// Produtos de [orcamento] com quantidade, preço unitário e total gravados
/// (D-39), na ordem do orçamento. Sem o custo das peças nem dos materiais.
List<LinhaProdutoPdf> linhasProdutosPdf(Orcamento orcamento) {
  final resultados = {for (final r in orcamento.totais.itens) r.itemId: r};
  return [
    for (final item in orcamento.itens)
      if (resultados[item.id] case final resultado?)
        (
          descricao: item.descricao,
          observacoes: switch (item.observacoes?.trim()) {
            final texto? when texto.isNotEmpty => texto,
            _ => null,
          },
          quantidade: '${item.quantidadeProdutos}',
          precoUnitario: resultado.precoUnitario.formatado,
          total: resultado.totalItem.formatado,
        ),
  ];
}

/// Totais gravados de [orcamento], na ordem da D-39: total dos produtos,
/// cada adicional maior que zero, subtotal, desconto (se houver) e total
/// geral. Sem recalcular.
List<LinhaTotalPdf> linhasTotaisPdf(Orcamento orcamento) {
  final totais = orcamento.totais;
  LinhaTotalPdf linha(String rotulo, String valor) =>
      (rotulo: rotulo, valor: valor, destaque: false);
  final outros = orcamento.outrosDescricao?.trim() ?? '';
  return [
    linha('Total dos produtos', totais.totalProdutos.formatado),
    for (final (rotulo, Dinheiro valor) in [
      ('Insumos', orcamento.insumos),
      ('Impostos', orcamento.impostos),
      ('Combustível', orcamento.combustivel),
      (outros.isEmpty ? 'Outros' : 'Outros: $outros', orcamento.outros),
    ])
      if (valor.ehPositivo) linha(rotulo, valor.formatado),
    linha('Subtotal', totais.subtotal.formatado),
    if (totais.desconto.ehPositivo)
      linha('Desconto', '− ${totais.desconto.formatado}'),
    (rotulo: 'Total geral', valor: totais.totalGeral.formatado, destaque: true),
  ];
}

/// PDF do orçamento que vai para o cliente (Tela 7, RF-40): logo, código
/// (com a revisão), emissão (a revisão atual), validade (só se houver),
/// emitente e cliente das cópias gravadas, produtos e totais conforme a
/// D-39 e as observações, se houver.
///
/// Sem redesenho (o documento comercial é outra tarefa, prompt §1). Nunca
/// mostra o custo das peças nem dos materiais (D-39).
Future<Uint8List> gerarOrcamentoPdf(Orcamento orcamento) async {
  final logo = pw.MemoryImage(
    (await rootBundle.load(_logoAsset)).buffer.asUint8List(),
  );
  final tema = pw.ThemeData.withFont(
    base: await _carregarFonte(fontePdfRegular),
    bold: await _carregarFonte(fontePdfNegrito),
  );
  final documento =
      pw.Document(
        title: 'Orçamento Nº ${orcamento.codigoExibicao}',
        author: orcamento.emitente.nomeRazaoSocial,
        theme: tema,
      )..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _cabecalho(orcamento, logo),
            pw.SizedBox(height: 24),
            _secao('EMISSOR', _linhasEmitente(orcamento)),
            pw.SizedBox(height: 16),
            _secao('CLIENTE', _linhasCliente(orcamento)),
            pw.SizedBox(height: 24),
            _cabecalhoItens(),
            for (final linha in linhasProdutosPdf(orcamento)) _linhaItem(linha),
            pw.SizedBox(height: 16),
            _totais(linhasTotaisPdf(orcamento)),
            ..._observacoes(orcamento),
          ],
        ),
      );
  return await documento.save();
}

pw.Widget _cabecalho(Orcamento orcamento, pw.ImageProvider logo) => pw.Center(
  child: pw.Column(
    children: [
      pw.Image(logo, height: 48),
      pw.SizedBox(height: 12),
      pw.Text(
        'ORÇAMENTO',
        style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Nº ${orcamento.codigoExibicao}',
        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 8),
      // A emissão é a da revisão atual, de onde conta a validade (D-30).
      _pequeno('Emissão: ${formatarData(orcamento.atualizadoEm)}'),
      if (orcamento.dataValidade case final validade?)
        _pequeno('Validade: até ${formatarData(validade)}'),
    ],
  ),
);

String _rotuloDocumento(Documento documento) =>
    documento.ehPessoaJuridica ? 'CNPJ' : 'CPF';

List<pw.Widget> _linhasEmitente(Orcamento orcamento) {
  final emitente = orcamento.emitente;
  final email = emitente.email;
  return [
    _negrito(emitente.nomeRazaoSocial),
    pw.Text(
      '${_rotuloDocumento(emitente.documento)}: '
      '${emitente.documento.formatado}',
    ),
    pw.Text(emitente.endereco.formatado),
    pw.Text(emitente.telefone),
    if (email != null && email.isNotEmpty) pw.Text(email),
  ];
}

List<pw.Widget> _linhasCliente(Orcamento orcamento) {
  final cliente = orcamento.cliente;
  return [
    _negrito(cliente.nome),
    pw.Text(
      '${_rotuloDocumento(cliente.documento)}: ${cliente.documento.formatado}',
    ),
    pw.Text(cliente.celular),
    pw.Text(cliente.endereco.formatado),
  ];
}

pw.Widget _secao(String titulo, List<pw.Widget> linhas) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    _rotulo(titulo),
    pw.Divider(color: PdfColors.grey300, height: 8),
    ...linhas,
  ],
);

/// Larguras das colunas de quantidade, preço unitário e total.
const double _colunaQtd = 40;
const double _colunaValor = 90;

pw.Widget _colunas(
  pw.Widget descricao,
  pw.Widget quantidade,
  pw.Widget unitario,
  pw.Widget total,
) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Expanded(child: descricao),
    pw.SizedBox(width: 8),
    pw.SizedBox(
      width: _colunaQtd,
      child: pw.Align(alignment: pw.Alignment.topRight, child: quantidade),
    ),
    pw.SizedBox(
      width: _colunaValor,
      child: pw.Align(alignment: pw.Alignment.topRight, child: unitario),
    ),
    pw.SizedBox(
      width: _colunaValor,
      child: pw.Align(alignment: pw.Alignment.topRight, child: total),
    ),
  ],
);

pw.Widget _cabecalhoItens() => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 6),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
  ),
  child: _colunas(
    _rotulo('PRODUTO'),
    _rotulo('QTD'),
    _rotulo('UNITÁRIO'),
    _rotulo('TOTAL'),
  ),
);

/// Produto: descrição, observações, quantidade, preço unitário e total.
pw.Widget _linhaItem(LinhaProdutoPdf linha) {
  final observacoes = linha.observacoes;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
    ),
    child: _colunas(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(linha.descricao, style: const pw.TextStyle(fontSize: 12)),
          if (observacoes != null) _pequeno(observacoes),
        ],
      ),
      pw.Text(linha.quantidade),
      pw.Text(linha.precoUnitario),
      pw.Text(linha.total),
    ),
  );
}

const pw.TextStyle _estiloDestaque = pw.TextStyle(
  fontSize: 13,
  fontWeight: pw.FontWeight.bold,
);

/// Totais gravados (D-39), sem recalcular.
pw.Widget _totais(List<LinhaTotalPdf> linhas) => pw.Column(
  children: [
    for (final linha in linhas)
      pw.Container(
        padding: pw.EdgeInsets.only(top: linha.destaque ? 10 : 4),
        margin: pw.EdgeInsets.only(top: linha.destaque ? 6 : 0),
        decoration: linha.destaque
            ? const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
              )
            : null,
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                linha.rotulo,
                style: linha.destaque ? _estiloDestaque : null,
              ),
            ),
            pw.Text(
              linha.valor,
              style: linha.destaque ? _estiloDestaque : null,
            ),
          ],
        ),
      ),
  ],
);

/// Observações gerais do orçamento, só se houver.
List<pw.Widget> _observacoes(Orcamento orcamento) {
  final texto = orcamento.observacoes?.trim() ?? '';
  if (texto.isEmpty) return const [];
  return [
    pw.SizedBox(height: 24),
    _secao('OBSERVAÇÕES', [pw.Text(texto)]),
  ];
}

pw.Widget _rotulo(String texto) => pw.Text(
  texto,
  style: const pw.TextStyle(
    fontSize: 9,
    letterSpacing: 1,
    color: PdfColors.grey700,
  ),
);

pw.Widget _negrito(String texto) =>
    pw.Text(texto, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold));

pw.Widget _pequeno(String texto) => pw.Text(
  texto,
  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
);
