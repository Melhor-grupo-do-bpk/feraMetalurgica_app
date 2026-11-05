import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';

/// Contrato de persistência dos materiais (prompt §7).
///
/// Não crie uma segunda implementação/local de acesso a materiais: toda
/// leitura/escrita de materiais passa por aqui. Materiais não são excluídos,
/// só inativados.
abstract class MaterialRepository {
  /// Materiais ativos, para novas seleções, ordenados por nome. Com
  /// [filtro], só os que contêm o texto no nome (sem diferenciar
  /// maiúsculas).
  Future<List<Material>> listarAtivos({String? filtro});

  /// Todos os materiais, ativos e inativos, ordenados por nome (tela de
  /// cadastro).
  Future<List<Material>> listarTodos();

  /// O material de identificador [id], ou `null` se não existir.
  Future<Material?> buscarPorId(String id);

  /// Cria ou atualiza um material.
  Future<void> salvar(Material material);

  /// Marca o material [id] como inativo: some das novas seleções, mas
  /// continua nas peças que já o copiaram.
  Future<void> inativar(String id);

  /// Marca o material [id] como ativo de novo.
  Future<void> reativar(String id);

  /// Se alguma peça de orçamento salvo copiou o material [id] (D-40). Um
  /// material em uso não troca de unidade (prompt §3.1).
  Future<bool> estaEmUso(String id);
}
