import 'package:pdf/pdf.dart';

/// Cores do PDF do orçamento (D-44), as do protótipo em
/// `docs/referencias/prototipo-orcamento-fera.pdf`. São `PdfColor` do pacote
/// `pdf`, não `Color` do Flutter: o documento não segue o tema claro/escuro
/// do app e não usa outras cores além destas.
abstract final class PdfTema {
  /// Títulos, cabeçalho da tabela e linhas fortes.
  static const PdfColor marrom = PdfColor.fromInt(0xFF5A2A0A);

  /// Destaques: número do orçamento, linha do cabeçalho e total geral.
  static const PdfColor laranja = PdfColor.fromInt(0xFFBA5E1B);

  /// Texto principal.
  static const PdfColor texto = PdfColor.fromInt(0xFF2A2420);

  /// Texto secundário e rótulos.
  static const PdfColor cinza = PdfColor.fromInt(0xFF6E655E);

  /// Linhas finas entre os itens e no rodapé.
  static const PdfColor linha = PdfColor.fromInt(0xFFD9D0C8);
}
