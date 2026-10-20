import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tarefa.freezed.dart';
part 'tarefa.g.dart';

/// Uma tarefa do cronograma (calendário + lista do dia).
@freezed
abstract class Tarefa with _$Tarefa {
  /// Cria uma [Tarefa].
  const factory Tarefa({
    /// Identificador único da tarefa.
    required String id,

    /// Título da tarefa.
    required String titulo,

    /// Data/hora da tarefa.
    required DateTime data,

    /// Tipo da tarefa (orçamento, produção ou visita).
    required TipoTarefa tipo,

    /// Se a tarefa já foi concluída.
    @Default(false) bool concluida,

    /// Texto livre exibido abaixo do título (ex: "Cliente: João da Silva").
    String? descricao,

    /// Identificador do `Orcamento` relacionado, quando houver; habilita o
    /// atalho "Ver Detalhes" na agenda (D-05).
    String? orcamentoId,
  }) = _Tarefa;

  /// Cria uma [Tarefa] a partir de um mapa JSON.
  factory Tarefa.fromJson(Map<String, dynamic> json) => _$TarefaFromJson(json);
}
