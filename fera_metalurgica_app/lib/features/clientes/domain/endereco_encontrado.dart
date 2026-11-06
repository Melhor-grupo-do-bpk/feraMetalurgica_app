import 'package:freezed_annotation/freezed_annotation.dart';

part 'endereco_encontrado.freezed.dart';
part 'endereco_encontrado.g.dart';

/// Endereço achado pelo CEP ou pela localização do celular. Um campo vazio
/// é um dado que o serviço não trouxe (ex: o [logradouro] do CEP geral de
/// uma cidade pequena).
@freezed
abstract class EnderecoEncontrado with _$EnderecoEncontrado {
  /// Cria um [EnderecoEncontrado].
  const factory EnderecoEncontrado({
    @JsonKey(name: 'localidade') required String cidade,
    required String uf,
    @Default('') String logradouro,
    @Default('') String bairro,
    @Default('') String cep,
  }) = _EnderecoEncontrado;

  /// Lê o JSON do serviço de CEP.
  factory EnderecoEncontrado.fromJson(Map<String, dynamic> json) =>
      _$EnderecoEncontradoFromJson(json);
}
