import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 1, cliente. Stub da F2: só escolhe um cliente já cadastrado, pela
/// busca, para o fluxo funcionar de ponta a ponta.
// TODO(V2-B): formulário completo (prompt §3.3): busca, cópia editável,
// cliente novo e aviso de troca de documento.
class EtapaCliente extends ConsumerStatefulWidget {
  /// Cria a etapa.
  const EtapaCliente({super.key});

  @override
  ConsumerState<EtapaCliente> createState() => _EtapaClienteState();
}

class _EtapaClienteState extends ConsumerState<EtapaCliente> {
  String _termo = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selecionado = ref.watch(orcamentoControllerProvider).edicao?.cliente;
    final clientes = ref.watch(buscaClientesProvider(_termo)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selecionado == null
              ? 'Nenhum cliente selecionado'
              : 'Cliente: ${selecionado.nome}',
          style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('wizard-busca-cliente'),
          onChanged: (termo) => setState(() => _termo = termo),
          decoration: const InputDecoration(
            hintText: 'Buscar cliente cadastrado',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final cliente in clientes ?? const <Cliente>[])
          ListTile(
            title: Text(cliente.nome),
            subtitle: Text(cliente.documento.formatado),
            selected: selecionado?.documento == cliente.documento,
            onTap: () => ref
                .read(orcamentoControllerProvider.notifier)
                .selecionarCliente(cliente),
          ),
      ],
    );
  }
}
