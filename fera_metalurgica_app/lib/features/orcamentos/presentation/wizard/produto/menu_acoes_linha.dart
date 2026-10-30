import 'package:flutter/material.dart';

/// Ações do menu de uma peça ou de um produto.
enum AcaoLinha {
  /// Carrega no formulário.
  editar,

  /// Cria uma cópia logo depois, com id novo.
  duplicar,

  /// Remove (com confirmação).
  remover,
}

/// Menu "Editar / Duplicar / Remover" das peças e dos produtos.
class MenuAcoesLinha extends StatelessWidget {
  /// Cria o menu; [tooltip] nomeia o botão para o leitor de tela.
  const MenuAcoesLinha({
    required this.tooltip,
    required this.onSelecionar,
    super.key,
  });

  /// Rótulo do botão (ex: "Ações da peça Tampo").
  final String tooltip;

  /// Chamado com a ação escolhida; `null` desabilita o menu.
  final ValueChanged<AcaoLinha>? onSelecionar;

  @override
  Widget build(BuildContext context) => PopupMenuButton<AcaoLinha>(
    tooltip: tooltip,
    enabled: onSelecionar != null,
    icon: const Icon(Icons.more_vert),
    onSelected: onSelecionar,
    itemBuilder: (_) => const [
      PopupMenuItem(value: AcaoLinha.editar, child: Text('Editar')),
      PopupMenuItem(value: AcaoLinha.duplicar, child: Text('Duplicar')),
      PopupMenuItem(value: AcaoLinha.remover, child: Text('Remover')),
    ],
  );
}
