import 'package:fera_metalurgica_app/core/constants/app_constants.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String _logoAsset = 'assets/images/logo_fera.png';

/// Trocas de caracteres fora do Latin-1 por equivalentes que a fonte
/// padrão do PDF consegue desenhar.
const Map<int, String> _equivalentesLatin1 = {
  0x2018: "'", // ‘
  0x2019: "'", // ’
  0x201A: "'", // ‚
  0x201B: "'", // ‛
  0x2032: "'", // ′
  0x201C: '"', // “
  0x201D: '"', // ”
  0x201E: '"', // „
  0x201F: '"', // ‟
  0x2033: '"', // ″
  0x2010: '-', // ‐
  0x2011: '-', // ‑
  0x2012: '-', // ‒
  0x2013: '-', // –
  0x2014: '-', // —
  0x2015: '-', // ―
  0x2212: '-', // −
  0x2022: '·', // •
  0x2026: '...', // …
};

// TODO(T8): embutir uma fonte TTF em assets/ para desenhar qualquer
// caractere e dispensar esta troca (HO-T5-01).
/// [texto] só com caracteres Latin-1, os únicos que a fonte padrão do PDF
/// (Helvetica) desenha; fora dela, o `pdf` falha.
///
/// Aspas curvas viram retas, travessões viram hífen, "•" vira "·",
/// reticências viram "...", espaços especiais viram espaço comum e o
/// resto (emoji, outros alfabetos) vira "?".
String textoParaPdf(String texto) {
  final saida = StringBuffer();
  for (final rune in texto.runes) {
    if (rune <= 0xFF) {
      saida.writeCharCode(rune);
    } else if (_equivalentesLatin1[rune] case final equivalente?) {
      saida.write(equivalente);
    } else if ((rune >= 0x2000 && rune <= 0x200A) ||
        rune == 0x202F ||
        rune == 0x205F ||
        rune == 0x3000) {
      saida.write(' ');
    } else {
      saida.write('?');
    }
  }
  return saida.toString();
}

/// PDF do orçamento que vai para o cliente (Tela 7, RF-40): logo, número,
/// data, validade, emissor, cliente, itens com quantidade e o valor total.
///
/// Nunca mostra custos internos (D-16) nem valor por item (D-01).
Future<Uint8List> gerarOrcamentoPdf(Orcamento orcamento) async {
  final logo = pw.MemoryImage(
    (await rootBundle.load(_logoAsset)).buffer.asUint8List(),
  );
  final documento =
      pw.Document(
        title: 'Orçamento Nº ${orcamento.id}',
        author: AppConstants.emissorNome,
      )..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _cabecalho(orcamento, logo),
            pw.SizedBox(height: 24),
            _secao('EMISSOR', [
              _negrito(AppConstants.emissorNome),
              pw.Text('CNPJ: ${AppConstants.emissorCnpj}'),
              pw.Text(AppConstants.emissorEndereco),
              pw.Text(AppConstants.emissorCidade),
              pw.Text(AppConstants.emissorTelefone),
            ]),
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
        'Nº ${orcamento.id}',
        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 8),
      _pequeno('Data: ${formatarData(orcamento.criadoEm)}'),
      _pequeno('Validade: ${AppConstants.validadeOrcamentoDias} dias'),
    ],
  ),
);

List<pw.Widget> _linhasCliente(Orcamento orcamento) {
  final cliente = orcamento.cliente;
  final documento = cliente.ehPessoaJuridica ? 'CNPJ' : 'CPF';
  final email = cliente.email;
  return [
    _negrito(textoParaPdf(cliente.nome)),
    pw.Text('$documento: ${textoParaPdf(cliente.cpfCnpj)}'),
    pw.Text(textoParaPdf(cliente.numero)),
    if (email != null && email.isNotEmpty) pw.Text(textoParaPdf(email)),
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

/// Item descritivo (D-01): tipo, medidas e material, especificações e
/// quantidade em "un". "·" no lugar do "•" de D-01, fora do Latin-1.
pw.Widget _linhaItem(ItemOrcamento item) {
  final detalhes = [
    item.medidas.formatada,
    item.materialPrincipal ?? '',
  ].where((t) => t.isNotEmpty).join(' · ');
  final especificacoes = item.especificacoes ?? '';
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
              pw.Text(
                textoParaPdf(item.tipoServico),
                style: const pw.TextStyle(fontSize: 12),
              ),
              if (detalhes.isNotEmpty) _pequeno(textoParaPdf(detalhes)),
              if (especificacoes.isNotEmpty)
                _pequeno(textoParaPdf(especificacoes)),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Text('${item.quantidade}\nun', textAlign: pw.TextAlign.right),
      ],
    ),
  );
}

/// Único valor do documento (D-01): `Orcamento.valorFinal`.
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
        pw.Text(formatarMoeda(orcamento.valorFinal), style: estilo),
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
