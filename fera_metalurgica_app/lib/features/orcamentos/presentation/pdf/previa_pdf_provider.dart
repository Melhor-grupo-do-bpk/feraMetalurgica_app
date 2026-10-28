import 'package:printing/printing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'previa_pdf_provider.g.dart';

/// Se a plataforma consegue desenhar a prévia do PDF (`canRaster`).
///
/// Sem isso, o `PdfPreview` fica carregando para sempre; a tela mostra um
/// aviso no lugar e mantém o "Baixar". Se a parte nativa do `printing` não
/// responder a tempo (é o caso dos testes de widget, em que a chamada ao
/// canal nunca volta), conta como indisponível.
@Riverpod(keepAlive: true)
Future<bool> previaPdfDisponivel(Ref ref) async {
  final info = await Printing.info().timeout(
    const Duration(seconds: 2),
    onTimeout: () => PrintingInfo.unavailable,
  );
  return info.canRaster;
}
