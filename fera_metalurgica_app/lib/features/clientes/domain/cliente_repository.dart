import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/cliente.dart';

/// Contrato de persistência dos clientes (prompt §7).
///
/// Não crie uma segunda implementação/local de acesso a clientes: toda
/// leitura/escrita de clientes passa por aqui. O documento normalizado é
/// único: salvar um cliente com o documento de outro é erro.
abstract class ClienteRepository {
  /// O cliente com o [documento] normalizado, ou `null` se não houver.
  Future<Cliente?> buscarPorDocumento(Documento documento);

  /// Clientes cujo nome, celular ou documento contêm [termo] (nome sem
  /// diferenciar maiúsculas; celular e documento comparados só pelos
  /// dígitos), ordenados por nome.
  Future<List<Cliente>> pesquisar(String termo);

  /// Cria ou atualiza um cliente.
  Future<void> salvar(Cliente cliente);
}
