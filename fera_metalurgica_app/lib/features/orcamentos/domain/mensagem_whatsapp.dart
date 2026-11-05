import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';

/// Texto que acompanha o PDF de [orcamento] no WhatsApp (RF-34, D-43):
/// saudação, código (com a revisão, D-30) e emitente da cópia. Os valores
/// ficam no PDF.
String montarMensagemWhatsApp(Orcamento orcamento) =>
    'Olá, ${orcamento.cliente.nome}! Segue o orçamento '
    'Nº ${orcamento.codigoExibicao} da '
    '${orcamento.emitente.nomeRazaoSocial}.';
