import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/pdf/pdf_tema.dart';
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

/// Margem da folha A4: 20 mm.
const double _margem = 20 * PdfPageFormat.mm;

/// Largura do bloco de totais: 78 mm.
const double _larguraTotais = 78 * PdfPageFormat.mm;

/// PDF do orçamento que vai para o cliente (Tela 7, RF-40), no layout do
/// protótipo `docs/referencias/prototipo-orcamento-fera.pdf` (D-44):
/// cabeçalho com a logo e o código, emitente e cliente das cópias gravadas,
/// tabela de produtos, totais conforme a D-39, observações e as linhas de
/// assinatura. O rodapé repete o emitente e o código, e numera as páginas
/// quando há mais de uma.
///
/// Nunca mostra o custo das peças nem dos materiais (D-39).
Future<Uint8List> gerarOrcamentoPdf(Orcamento orcamento) async {
  final logo = pw.MemoryImage(
    (await rootBundle.load(_logoAsset)).buffer.asUint8List(),
  );
  final fontes = pw.ThemeData.withFont(
    base: await _carregarFonte(fontePdfRegular),
    bold: await _carregarFonte(fontePdfNegrito),
  );
  final tema = fontes.copyWith(
    defaultTextStyle: fontes.defaultTextStyle.copyWith(
      fontSize: 10,
      color: PdfTema.texto,
    ),
  );
  final documento =
      pw.Document(
        title: 'Orçamento Nº ${orcamento.codigoExibicao}',
        author: orcamento.emitente.nomeRazaoSocial,
        theme: tema,
      )..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_margem),
          footer: (context) => _rodape(orcamento, context),
          build: (context) => [
            _cabecalho(orcamento, logo),
            pw.SizedBox(height: 14),
            pw.Container(height: 1.5, color: PdfTema.laranja),
            pw.SizedBox(height: 22),
            _partes(orcamento),
            pw.SizedBox(height: 26),
            _tabelaProdutos(linhasProdutosPdf(orcamento)),
            pw.SizedBox(height: 20),
            // Inteiros: os totais, as observações e as assinaturas não se
            // dividem entre páginas.
            pw.Inseparable(child: _totais(linhasTotaisPdf(orcamento))),
            ..._observacoes(orcamento),
            pw.SizedBox(height: 64),
            pw.Inseparable(child: _assinaturas(orcamento)),
          ],
        ),
      );
  return await documento.save();
}

/// Logo à esquerda; "ORÇAMENTO", código, emissão e validade à direita.
pw.Widget _cabecalho(Orcamento orcamento, pw.ImageProvider logo) {
  final validade = orcamento.dataValidade;
  // A emissão é a da revisão atual, de onde conta a validade (D-30).
  final datas = [
    'Emissão ${formatarData(orcamento.atualizadoEm)}',
    if (validade != null) 'Validade ${formatarData(validade)}',
  ].join(' · ');
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _logo(logo),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'ORÇAMENTO',
            style: const pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfTema.marrom,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Nº ${orcamento.codigoExibicao}',
            style: const pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfTema.laranja,
            ),
          ),
          pw.SizedBox(height: 4),
          _secundario(datas, tamanho: 9),
        ],
      ),
    ],
  );
}

/// A marca do app: o "F" da logo, "ERA" em marrom com o ponto laranja e
/// "METALÚRGICA" embaixo, como no app (`AppLogo`) e no protótipo.
pw.Widget _logo(pw.ImageProvider logo) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // A caixa do texto inclui o espaço abaixo da linha de base: sem
        // este recuo, o "F" fica mais baixo que "ERA".
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Image(logo, height: 24),
        ),
        pw.RichText(
          text: const pw.TextSpan(
            text: 'ERA',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfTema.marrom,
              lineSpacing: 0,
            ),
            children: [
              pw.TextSpan(
                text: '.',
                style: pw.TextStyle(color: PdfTema.laranja),
              ),
            ],
          ),
        ),
      ],
    ),
    pw.SizedBox(height: 4),
    _rotulo('METALÚRGICA'),
  ],
);

/// "CNPJ 00.000.000/0000-00" ou "CPF 000.000.000-00".
String _documentoComRotulo(Documento documento) =>
    '${documento.ehPessoaJuridica ? 'CNPJ' : 'CPF'} ${documento.formatado}';

/// Endereço em até três linhas: logradouro, número e complemento; bairro,
/// cidade e UF; CEP, se houver.
List<String> _linhasEndereco(Endereco endereco) {
  final complemento = endereco.complemento?.trim() ?? '';
  final cep = endereco.cep?.trim() ?? '';
  return [
    [
      '${endereco.logradouro}, ${endereco.numero}',
      if (complemento.isNotEmpty) complemento,
    ].join(' – '),
    '${endereco.bairro}, ${endereco.cidade} – ${endereco.uf}',
    if (cep.isNotEmpty) 'CEP ${formatarCep(cep)}',
  ];
}

/// Emitente e cliente lado a lado, das cópias gravadas no orçamento.
pw.Widget _partes(Orcamento orcamento) {
  final emitente = orcamento.emitente;
  final cliente = orcamento.cliente;
  final email = emitente.email?.trim() ?? '';
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: _parte('EMISSOR', emitente.nomeRazaoSocial, [
          _documentoComRotulo(emitente.documento),
          ..._linhasEndereco(emitente.endereco),
          formatarTelefone(emitente.telefone),
          if (email.isNotEmpty) email,
        ]),
      ),
      pw.SizedBox(width: 24),
      pw.Expanded(
        child: _parte('CLIENTE', cliente.nome, [
          _documentoComRotulo(cliente.documento),
          ..._linhasEndereco(cliente.endereco),
          formatarTelefone(cliente.celular),
        ]),
      ),
    ],
  );
}

pw.Widget _parte(String titulo, String nome, List<String> linhas) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    _rotulo(titulo),
    pw.SizedBox(height: 8),
    pw.Text(
      nome,
      style: const pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 3),
    for (final linha in linhas)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2),
        child: _secundario(linha, tamanho: 9.5),
      ),
  ],
);

/// Tabela de produtos. Como `pw.Table`, repete o cabeçalho em cada página e
/// não corta uma linha ao meio.
pw.Widget _tabelaProdutos(List<LinhaProdutoPdf> linhas) {
  const forte = pw.BorderSide(color: PdfTema.marrom, width: 1.5);
  return pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(26),
      1: pw.FlexColumnWidth(),
      2: pw.FixedColumnWidth(40),
      3: pw.FixedColumnWidth(84),
      4: pw.FixedColumnWidth(84),
    },
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: forte, bottom: forte),
        ),
        children: [
          _celulaCabecalho('#'),
          _celulaCabecalho('DESCRIÇÃO DO PRODUTO'),
          _celulaCabecalho('QTD', alinhamento: pw.Alignment.center),
          _celulaCabecalho(
            'VALOR UNIT.',
            alinhamento: pw.Alignment.centerRight,
          ),
          _celulaCabecalho('TOTAL', alinhamento: pw.Alignment.centerRight),
        ],
      ),
      for (final (i, linha) in linhas.indexed)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfTema.linha)),
          ),
          children: [
            _celula(_secundario('${i + 1}'.padLeft(2, '0'), tamanho: 10.5)),
            _celula(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    linha.descricao,
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                  if (linha.observacoes case final observacoes?) ...[
                    pw.SizedBox(height: 2),
                    _secundario(observacoes, tamanho: 9),
                  ],
                ],
              ),
            ),
            _celula(
              pw.Text(linha.quantidade),
              alinhamento: pw.Alignment.topCenter,
            ),
            _celula(
              pw.Text(linha.precoUnitario),
              alinhamento: pw.Alignment.topRight,
            ),
            _celula(pw.Text(linha.total), alinhamento: pw.Alignment.topRight),
          ],
        ),
    ],
  );
}

pw.Widget _celulaCabecalho(
  String texto, {
  pw.Alignment alinhamento = pw.Alignment.centerLeft,
}) => pw.Container(
  alignment: alinhamento,
  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  child: pw.Text(
    texto,
    style: const pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 1,
      color: PdfTema.marrom,
    ),
  ),
);

pw.Widget _celula(
  pw.Widget conteudo, {
  pw.Alignment alinhamento = pw.Alignment.topLeft,
}) => pw.Container(
  alignment: alinhamento,
  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
  child: conteudo,
);

/// Totais gravados (D-39), sem recalcular, alinhados à direita. O total
/// geral vem depois de uma linha marrom, com o valor em laranja.
pw.Widget _totais(List<LinhaTotalPdf> linhas) => pw.Align(
  alignment: pw.Alignment.centerRight,
  child: pw.SizedBox(
    width: _larguraTotais,
    child: pw.Column(
      children: [
        for (final linha in linhas)
          if (linha.destaque)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              padding: const pw.EdgeInsets.only(top: 10, left: 4, right: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfTema.marrom)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      linha.rotulo,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    linha.valor,
                    style: const pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfTema.laranja,
                    ),
                  ),
                ],
              ),
            )
          else
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(linha.rotulo)),
                  pw.Text(linha.valor),
                ],
              ),
            ),
      ],
    ),
  ),
);

/// Observações gerais do orçamento, só se houver.
List<pw.Widget> _observacoes(Orcamento orcamento) {
  final texto = orcamento.observacoes?.trim() ?? '';
  if (texto.isEmpty) return const [];
  return [
    pw.SizedBox(height: 28),
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _rotulo('OBSERVAÇÕES'),
          pw.SizedBox(height: 6),
          _secundario(texto, tamanho: 9.5),
        ],
      ),
    ),
  ];
}

/// Linhas de assinatura do emitente e do cliente.
pw.Widget _assinaturas(Orcamento orcamento) => pw.Row(
  children: [
    pw.Expanded(child: _assinatura(orcamento.emitente.nomeRazaoSocial)),
    pw.SizedBox(width: 28),
    pw.Expanded(child: _assinatura(orcamento.cliente.nome)),
  ],
);

pw.Widget _assinatura(String nome) => pw.Container(
  padding: const pw.EdgeInsets.only(top: 8),
  decoration: const pw.BoxDecoration(
    border: pw.Border(top: pw.BorderSide(color: PdfTema.texto)),
  ),
  child: pw.Center(child: _secundario(nome, tamanho: 9.5)),
);

/// Rodapé de cada página: emitente à esquerda, código à direita e o número
/// da página só quando há mais de uma.
pw.Widget _rodape(Orcamento orcamento, pw.Context context) {
  final emitente = orcamento.emitente;
  final pagina = context.pagesCount > 1
      ? ' · Página ${context.pageNumber} de ${context.pagesCount}'
      : '';
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 16),
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: PdfTema.linha)),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: _secundario(
            '${emitente.nomeRazaoSocial} · '
            '${_documentoComRotulo(emitente.documento)}',
            tamanho: 8,
          ),
        ),
        _secundario(
          'Orçamento Nº ${orcamento.codigoExibicao}$pagina',
          tamanho: 8,
        ),
      ],
    ),
  );
}

/// Rótulo em caixa alta, pequeno e espaçado (ex: "EMISSOR").
pw.Widget _rotulo(String texto) => pw.Text(
  texto,
  style: const pw.TextStyle(
    fontSize: 8,
    letterSpacing: 1.5,
    color: PdfTema.cinza,
  ),
);

pw.Widget _secundario(String texto, {required double tamanho}) => pw.Text(
  texto,
  style: pw.TextStyle(fontSize: tamanho, color: PdfTema.cinza),
);
