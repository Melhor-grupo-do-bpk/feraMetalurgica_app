import 'package:fera_metalurgica_app/features/clientes/domain/endereco_encontrado.dart';

/// Por que a localização do celular não virou um endereço.
enum MotivoFalhaLocalizacao {
  /// O aparelho não tem o serviço (ex: o Windows, em desenvolvimento).
  indisponivel,

  /// A localização do aparelho está desligada.
  gpsDesligado,

  /// O operador não deu a permissão de localização.
  semPermissao,

  /// Não há endereço para o ponto em que o aparelho está.
  semEndereco,
}

/// Falha conhecida ao buscar o endereço da localização atual.
class FalhaLocalizacao implements Exception {
  /// Cria a falha.
  const FalhaLocalizacao(this.motivo);

  /// O que aconteceu.
  final MotivoFalhaLocalizacao motivo;
}

/// Endereço do lugar em que o aparelho está (D-43).
abstract class LocalizacaoRepository {
  /// Endereço da localização atual. Lança [FalhaLocalizacao] nos casos
  /// previstos e outra `Exception` se o serviço falhar.
  Future<EnderecoEncontrado> enderecoAtual();
}
