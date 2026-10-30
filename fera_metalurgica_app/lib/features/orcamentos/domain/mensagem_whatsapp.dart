import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';

/// Mensagem de resumo de [orcamento] enviada ao cliente pelo WhatsApp
/// (RF-34, D-15): saudação, código (com a revisão, D-30), emitente da
/// cópia, total geral gravado e a validade, só se houver.
///
/// É um documento do cliente: nunca inclui custos internos (D-16).
String montarMensagemWhatsApp(Orcamento orcamento) {
  final validade = orcamento.dataValidade;
  return 'Olá, ${orcamento.cliente.nome}! Segue o resumo do orçamento '
      'Nº ${orcamento.codigoExibicao} da '
      '${orcamento.emitente.nomeRazaoSocial}.\n'
      '\n'
      'Valor total: ${orcamento.totalGeral.formatado}'
      '${validade == null ? '' : '\nValidade: até ${formatarData(validade)}'}';
}
