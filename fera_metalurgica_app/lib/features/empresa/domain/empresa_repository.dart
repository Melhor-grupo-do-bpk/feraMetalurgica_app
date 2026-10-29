import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';

/// Contrato de persistência dos dados da empresa (prompt §7).
///
/// Não crie uma segunda implementação/local de acesso à empresa: toda
/// leitura/escrita da empresa passa por aqui.
abstract class EmpresaRepository {
  /// A empresa cadastrada, ou `null` se ainda não houver.
  Future<Empresa?> obter();

  /// Cria ou substitui a empresa. Garante um único emitente por instalação.
  Future<void> salvar(Empresa empresa);
}
