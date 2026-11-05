import 'package:fera_metalurgica_app/core/widgets/confirmar_acao.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exclui [orcamento] depois de confirmar, pela lista ou pelos detalhes.
/// [aoConfirmar] roda antes de excluir (os detalhes saem da tela).
///
/// O código não é reutilizado (D-30). As tarefas vinculadas ficam na agenda
/// sem o vínculo (D-38): a agenda é recarregada aqui, porque o
/// `orcamentosProvider` não depende da agenda.
Future<void> excluirOrcamento(
  BuildContext context,
  Orcamento orcamento, {
  VoidCallback? aoConfirmar,
}) async {
  final codigo = orcamento.codigoExibicao;
  final excluir = await confirmarAcao(
    context,
    titulo: 'Excluir o orçamento?',
    mensagem:
        'O orçamento $codigo sai da lista, e o código não volta a ser '
        'usado. As tarefas vinculadas continuam na agenda, sem o vínculo.',
    acao: 'Excluir',
  );
  if (!excluir || !context.mounted) return;

  // Depois de `aoConfirmar` a tela pode sumir: o container e o mensageiro
  // são guardados antes.
  final container = ProviderScope.containerOf(context, listen: false);
  final mensageiro = ScaffoldMessenger.of(context);
  aoConfirmar?.call();
  try {
    await container.read(orcamentosProvider.notifier).excluir(orcamento.id);
    container.invalidate(tarefasProvider);
    mensageiro.showSnackBar(
      SnackBar(content: Text('Orçamento $codigo excluído.')),
    );
  } on Exception catch (erro) {
    debugPrint('Falha ao excluir o orçamento: $erro');
    mensageiro.showSnackBar(
      const SnackBar(content: Text('Não foi possível excluir o orçamento.')),
    );
  }
}
