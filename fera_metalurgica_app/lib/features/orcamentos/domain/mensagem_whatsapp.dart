import 'package:fera_metalurgica_app/core/constants/app_constants.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';

/// Mensagem de resumo de [orcamento] enviada ao cliente pelo WhatsApp
/// (RF-34, D-15): saudação, número, projeto, valor final, prazo e validade.
///
/// É um documento do cliente: nunca inclui custos internos (D-16).
String montarMensagemWhatsApp(Orcamento orcamento) =>
    'Olá, ${orcamento.cliente.nome}! Segue o resumo do orçamento '
    'Nº ${orcamento.id} da ${AppConstants.emissorNome}.\n'
    '\n'
    'Projeto: ${orcamento.projeto}\n'
    'Valor total: ${formatarMoeda(orcamento.valorFinal)}\n'
    'Prazo: ${orcamento.prazoDiasUteis} dias úteis após aprovação e sinal\n'
    'Validade: ${AppConstants.validadeOrcamentoDias} dias';
