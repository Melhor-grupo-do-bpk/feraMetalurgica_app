import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
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

/// PDF do orçamento que vai para o cliente (Tela 7, RF-40): logo, código
/// (com a revisão), data, validade (só se houver), emitente e cliente das
/// cópias gravadas, produtos com quantidade e o total geral gravado.
///
/// Versão mínima da F2, sem redesenho (o documento comercial é outra
/// tarefa, prompt §1). Nunca mostra custos internos (D-16).
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
            for (final item in orcamento.itens) _linhaItem(item),
            pw.SizedBox(height: 16),
            _valorTotal(orcamento),
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
      _pequeno('Data: ${formatarData(orcamento.criadoEm)}'),
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

pw.Widget _cabecalhoItens() => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 6),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
  ),
  child: pw.Row(
    children: [
      pw.Expanded(child: _rotulo('DESCRIÇÃO DO ITEM / SERVIÇO')),
      _rotulo('QTD'),
    ],
  ),
);

/// Produto: descrição, observações e quantidade em "un".
pw.Widget _linhaItem(ItemOrcamento item) {
  final observacoes = item.observacoes ?? '';
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(item.descricao, style: const pw.TextStyle(fontSize: 12)),
              if (observacoes.isNotEmpty) _pequeno(observacoes),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Text(
          '${item.quantidadeProdutos}\nun',
          textAlign: pw.TextAlign.right,
        ),
      ],
    ),
  );
}

/// Total geral gravado (`Orcamento.totalGeral`), sem recalcular.
pw.Widget _valorTotal(Orcamento orcamento) {
  const estilo = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold);
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Text('Valor Total', style: estilo)),
        pw.Text(orcamento.totalGeral.formatado, style: estilo),
      ],
    ),
  );
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
