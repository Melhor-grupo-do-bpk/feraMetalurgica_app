import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';

/// "Agora" usado pelos testes que comparam com as datas da tela do Figma
/// (9 de outubro de 2023, 8h).
final DateTime agoraDosExemplos = DateTime(2023, 10, 9, 8);

/// As tarefas de exemplo (`cronogramaSeed`) geradas em [agoraDosExemplos],
/// sem vínculo com orçamento.
final List<Tarefa> tarefasExemplo = cronogramaSeed(agoraDosExemplos);

/// [edicao] salva como o `FinalizarOrcamentoService` gravaria, mas com
/// [id], [codigo] e datas fixos, para testes que não usam o banco.
Orcamento salvarExemplo(
  OrcamentoEmEdicao edicao, {
  required String id,
  required String codigo,
  required DateTime em,
  StatusOrcamento status = StatusOrcamento.criado,
  DateTime? enviadoEm,
}) => Orcamento(
  id: id,
  codigo: codigo,
  revisao: 1,
  chaveFinalizacao: edicao.chaveFinalizacao,
  criadoEm: em,
  atualizadoEm: em,
  status: status,
  enviadoEm: enviadoEm,
  cliente: edicao.cliente!,
  emitente: edicao.emitente,
  itens: edicao.itens,
  insumos: edicao.insumos,
  impostos: edicao.impostos,
  combustivel: edicao.combustivel,
  outros: edicao.outros,
  outrosDescricao: edicao.outrosDescricao,
  desconto: edicao.desconto,
  validadeDias: edicao.validadeDias,
  observacoes: edicao.observacoes,
  totais: const CalculadoraOrcamento().calcularOrcamento(
    itens: edicao.itens,
    insumos: edicao.insumos,
    impostos: edicao.impostos,
    combustivel: edicao.combustivel,
    outros: edicao.outros,
    desconto: edicao.desconto,
  ),
  versaoCalculo: CalculadoraOrcamento.versaoCalculo,
);

/// Gerador de ids previsíveis com o [prefixo] (`c-0`, `c-1`...).
String Function() idsPrevisiveis(String prefixo) {
  var proximo = 0;
  return () => '$prefixo-${proximo++}';
}

/// Exemplo C dos dados de debug (A + B, R$ 3.630,80, validade de 15 dias),
/// salvo em 07/10/2023 com o código `071023-01`.
final Orcamento orcamentoExemploC = salvarExemplo(
  edicaoExemploC(idsPrevisiveis('c')),
  id: 'orcamento-c',
  codigo: '071023-01',
  em: DateTime(2023, 10, 7, 10),
);

/// Exemplo B dos dados de debug (R$ 644,40, sem validade), salvo em
/// 08/10/2023 com o código `081023-01`.
final Orcamento orcamentoExemploB = salvarExemplo(
  edicaoExemploB(idsPrevisiveis('b')),
  id: 'orcamento-b',
  codigo: '081023-01',
  em: DateTime(2023, 10, 8, 15),
);

/// Um orçamento enviado e na 2ª revisão, de "Metalúrgica ABC Ltda": criado
/// em 05/10/2023 (`051023-02`), revisado e enviado em 09/10/2023.
final Orcamento orcamentoExemploEnviado = salvarExemplo(
  edicaoExemploB(idsPrevisiveis('e')).copyWith(
    cliente: clienteExemploPj.copyWith(
      nome: 'Metalúrgica ABC Ltda',
      documento: const Documento('11444777000161'),
    ),
  ),
  id: 'orcamento-e',
  codigo: '051023-02',
  em: DateTime(2023, 10, 9, 7),
  status: StatusOrcamento.enviado,
  enviadoEm: DateTime(2023, 10, 9, 7, 30),
).copyWith(revisao: 2, criadoEm: DateTime(2023, 10, 5, 9));

/// Os três orçamentos de exemplo, como `listarResumos` os devolve (do
/// `atualizadoEm` mais recente ao mais antigo).
final List<Orcamento> orcamentosExemplo = [
  orcamentoExemploEnviado,
  orcamentoExemploB,
  orcamentoExemploC,
];
