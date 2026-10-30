import 'package:fera_metalurgica_app/features/empresa/data/sqlite_empresa_repository.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'empresa_controller.g.dart';

/// A empresa emitente cadastrada, ou `null` se ainda não houver (prompt
/// §3.2).
///
/// Estado compartilhado da feature. Trilhas podem adicionar métodos, mas
/// não renomear/remover os existentes (`docs/03-padroes.md` §2).
@Riverpod(keepAlive: true)
class DadosEmpresa extends _$DadosEmpresa {
  @override
  Future<Empresa?> build() => ref.watch(empresaRepositoryProvider).obter();

  /// Cria ou substitui os dados da empresa.
  Future<void> salvar(Empresa empresa) async {
    await ref.read(empresaRepositoryProvider).salvar(empresa);
    state = AsyncData(empresa);
  }
}

/// Se a empresa está cadastrada e completa. Sem isso, "Novo orçamento" e
/// "Editar" levam a "Dados da empresa" (prompt §3.2; redirect das rotas do
/// wizard).
@riverpod
Future<bool> empresaCompleta(Ref ref) async =>
    (await ref.watch(dadosEmpresaProvider.future))?.estaCompleta ?? false;
