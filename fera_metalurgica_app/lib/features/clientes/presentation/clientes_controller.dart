import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/features/clientes/data/sqlite_cliente_repository.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/cliente.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clientes_controller.g.dart';

/// Clientes cujo nome, celular ou documento contêm [termo] (prompt §3.3),
/// ordenados por nome. Termo vazio lista todos.
@riverpod
Future<List<Cliente>> buscaClientes(Ref ref, String termo) =>
    ref.watch(clienteRepositoryProvider).pesquisar(termo);

/// O cliente cadastrado com o [documento] normalizado, ou `null`. Serve
/// para resolver a identidade de novo quando o documento muda na etapa 1.
@riverpod
Future<Cliente?> clientePorDocumento(Ref ref, Documento documento) =>
    ref.watch(clienteRepositoryProvider).buscarPorDocumento(documento);
