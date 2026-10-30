import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/codigo_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/unidade_de_trabalho.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/validacao_orcamento.dart';

/// A edição não passou na validação: nada foi gravado.
class OrcamentoInvalidoException implements Exception {
  /// Cria a exceção com os [erros] de `validarOrcamento`.
  const OrcamentoInvalidoException(this.erros);

  /// Erros encontrados, com o caminho de cada campo.
  final List<ErroValidacao> erros;

  @override
  String toString() =>
      'OrcamentoInvalidoException: ${erros.map((e) => e.mensagem).join('; ')}';
}

/// Grava o orçamento da sessão de edição (prompt §7 e §8, D-30): o único
/// lugar que cria ou atualiza um orçamento salvo.
///
/// 1. Revalida e recalcula, sem confiar nas telas.
/// 2. Numa transação: se a `chaveFinalizacao` já foi gravada, devolve o
///    orçamento gravado (clique duplo); senão, resolve o cliente pelo
///    documento normalizado (cria ou atualiza o cadastro) e:
///    - num orçamento novo, reserva a sequência do dia e grava a revisão 1,
///      `criado`;
///    - numa edição, grava a revisão + 1 no lugar da anterior, com o
///      `atualizadoEm` atual, o mesmo código e `criadoEm`, a chave nova e
///      o status de volta a `criado` (sem `enviadoEm`).
///
/// Se algo falhar, a transação desfaz tudo, inclusive a sequência, e o erro
/// é relançado: a sessão continua em memória para nova tentativa.
class FinalizarOrcamentoService {
  /// Cria o serviço. Os repositórios do prompt §7 (clientes, orçamentos e
  /// sequências) vêm da `unidadeDeTrabalho`, ligados à transação.
  const FinalizarOrcamentoService({
    required this._unidadeDeTrabalho,
    required this._relogio,
    required this._gerarId,
    this._calculadora = const CalculadoraOrcamento(),
  });

  final UnidadeDeTrabalho _unidadeDeTrabalho;
  final DateTime Function() _relogio;
  final String Function() _gerarId;
  final CalculadoraOrcamento _calculadora;

  /// Grava [edicao] e devolve o orçamento salvo. Lança
  /// [OrcamentoInvalidoException] se a edição for inválida e [StateError]
  /// se o orçamento em edição não existir mais.
  Future<Orcamento> executar(OrcamentoEmEdicao edicao) async {
    final erros = validarOrcamento(edicao);
    if (erros.isNotEmpty) throw OrcamentoInvalidoException(erros);
    final totais = _calculadora.calcularOrcamento(
      itens: edicao.itens,
      insumos: edicao.insumos,
      impostos: edicao.impostos,
      combustivel: edicao.combustivel,
      outros: edicao.outros,
      desconto: edicao.desconto,
    );
    final agora = _relogio();

    return await _unidadeDeTrabalho.executarEmTransacao((repos) async {
      final jaGravado = await repos.orcamentos.buscarPorChaveFinalizacao(
        edicao.chaveFinalizacao,
      );
      if (jaGravado != null) return jaGravado;

      final cliente = await _resolverCliente(repos.clientes, edicao.cliente!);

      Orcamento montar({
        required String id,
        required String codigo,
        required int revisao,
        required DateTime criadoEm,
      }) => Orcamento(
        id: id,
        codigo: codigo,
        revisao: revisao,
        chaveFinalizacao: edicao.chaveFinalizacao,
        criadoEm: criadoEm,
        atualizadoEm: agora,
        status: StatusOrcamento.criado,
        cliente: cliente,
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
        totais: totais,
        versaoCalculo: CalculadoraOrcamento.versaoCalculo,
      );

      final origemId = edicao.orcamentoOrigemId;
      if (origemId == null) {
        final sequencia = await repos.sequencias.proximaDoDia(agora);
        final novo = montar(
          id: _gerarId(),
          codigo: formatarCodigoOrcamento(agora, sequencia),
          revisao: 1,
          criadoEm: agora,
        );
        await repos.orcamentos.inserir(novo);
        return novo;
      }

      final anterior = await repos.orcamentos.buscarPorId(origemId);
      if (anterior == null) {
        throw StateError('O orçamento em edição não existe mais');
      }
      final revisado = montar(
        id: anterior.id,
        codigo: anterior.codigo,
        revisao: anterior.revisao + 1,
        criadoEm: anterior.criadoEm,
      );
      await repos.orcamentos.atualizar(revisado);
      return revisado;
    });
  }

  /// Cria ou atualiza o cadastro do cliente pelo documento normalizado e
  /// devolve a cópia com a origem.
  Future<ClienteSnapshot> _resolverCliente(
    ClienteRepository clientes,
    ClienteSnapshot copia,
  ) async {
    final existente = await clientes.buscarPorDocumento(copia.documento);
    final cliente = Cliente(
      id: existente?.id ?? _gerarId(),
      nome: copia.nome,
      documento: copia.documento,
      celular: copia.celular,
      endereco: copia.endereco,
    );
    await clientes.salvar(cliente);
    return cliente.gerarSnapshot();
  }
}
