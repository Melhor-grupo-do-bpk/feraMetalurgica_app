import 'package:fera_metalurgica_app/features/clientes/domain/endereco_encontrado.dart';

/// Consulta de endereço por CEP (D-43).
abstract class CepRepository {
  /// Endereço do [cep] (8 dígitos), ou `null` se o CEP não existir. Lança
  /// uma `Exception` sem internet ou se o serviço falhar.
  Future<EnderecoEncontrado?> buscar(String cep);
}
