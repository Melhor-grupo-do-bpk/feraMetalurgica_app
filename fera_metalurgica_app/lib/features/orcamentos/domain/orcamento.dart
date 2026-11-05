import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'orcamento.freezed.dart';
part 'orcamento.g.dart';

/// Orçamento salvo (D-26 e D-30): cópias de cliente e emitente, produtos com
/// peças, adicionais, desconto e os [totais] calculados ao salvar.
///
/// O valor final nunca é digitado: é o [totais] gerado pela
/// `CalculadoraOrcamento`. Consultar um orçamento salvo mostra os totais
/// gravados, sem recalcular. Editar grava uma nova revisão no lugar desta
/// (D-30); só a revisão atual é guardada.
@freezed
abstract class Orcamento with _$Orcamento {
  /// Cria um [Orcamento].
  const factory Orcamento({
    /// Identificador interno (UUID).
    required String id,

    /// Código exibido, `DDMMAA-NN` (ex: `281026-03`), gerado ao criar e
    /// nunca reutilizado (ver `formatarCodigoOrcamento`).
    required String codigo,

    /// Revisão atual: 1 ao criar, +1 a cada edição salva (D-30).
    required int revisao,

    /// Chave idempotente da gravação: repetir a mesma chave não cria nem
    /// grava outro orçamento.
    required String chaveFinalizacao,

    /// Quando o orçamento foi criado (a data do [codigo]).
    required DateTime criadoEm,

    /// Quando a revisão atual foi salva; a validade conta daqui.
    required DateTime atualizadoEm,

    /// Status (D-29).
    required StatusOrcamento status,

    /// Cópia do cliente.
    required ClienteSnapshot cliente,

    /// Cópia da empresa emitente.
    required EmpresaSnapshot emitente,

    /// Produtos, na ordem exibida.
    required List<ItemOrcamento> itens,

    /// Insumos do orçamento.
    @DinheiroJsonConverter() required Dinheiro insumos,

    /// Impostos informados (não calculados pelo app).
    @DinheiroJsonConverter() required Dinheiro impostos,

    /// Combustível.
    @DinheiroJsonConverter() required Dinheiro combustivel,

    /// Outros valores; exige [outrosDescricao] quando maior que zero.
    @DinheiroJsonConverter() required Dinheiro outros,

    /// Desconto sobre o subtotal.
    @DinheiroJsonConverter() required Dinheiro desconto,

    /// Totais calculados ao salvar.
    required ResultadoOrcamento totais,

    /// Versão da `CalculadoraOrcamento` que gerou os [totais].
    required int versaoCalculo,

    /// Descrição de [outros].
    String? outrosDescricao,

    /// Validade em dias corridos, contados de [atualizadoEm].
    int? validadeDias,

    /// Observações gerais.
    String? observacoes,

    /// Quando o status passou para `enviado` (pelo WhatsApp ou à mão);
    /// `null` enquanto `criado`. Os cards "Enviados no mês" contam por aqui
    /// (D-32, D-37). Mudar o status não mexe em [atualizadoEm].
    DateTime? enviadoEm,
  }) = _Orcamento;

  const Orcamento._();

  /// Cria um [Orcamento] a partir de um mapa JSON.
  factory Orcamento.fromJson(Map<String, dynamic> json) =>
      _$OrcamentoFromJson(json);

  /// Código para telas, PDF e WhatsApp: `281026-03`, ou `281026-03 rev. 2`
  /// a partir da 2ª revisão (D-30).
  String get codigoExibicao => revisao >= 2 ? '$codigo rev. $revisao' : codigo;

  /// Total geral gravado.
  Dinheiro get totalGeral => totais.totalGeral;

  /// Data-limite da validade (sem hora): [atualizadoEm] + [validadeDias]
  /// dias corridos; `null` sem validade.
  DateTime? get dataValidade {
    final dias = validadeDias;
    if (dias == null) return null;
    return DateTime(
      atualizadoEm.year,
      atualizadoEm.month,
      atualizadoEm.day + dias,
    );
  }
}
