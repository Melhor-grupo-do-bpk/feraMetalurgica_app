import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 1 do wizard (Tela 2): dados do cliente (RF-21).
///
/// Cada alteração vai direto para o controller, então voltar e avançar não
/// perde nada. A validação visual usa [formKey], que a página valida ao
/// tocar em "Continuar".
class EtapaCliente extends ConsumerStatefulWidget {
  /// Cria a etapa ligada ao wizard de [provider].
  const EtapaCliente({
    required this.provider,
    required this.formKey,
    super.key,
  });

  /// Provider do wizard aberto.
  final OrcamentoWizardControllerProvider provider;

  /// Chave do `Form` dos campos do cliente.
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<EtapaCliente> createState() => _EtapaClienteState();
}

class _EtapaClienteState extends ConsumerState<EtapaCliente> {
  late final TextEditingController _nome;
  late final TextEditingController _numero;
  late final TextEditingController _cpfCnpj;
  late final TextEditingController _email;
  late final TextEditingController _observacoes;

  @override
  void initState() {
    super.initState();
    final cliente = ref.read(widget.provider).requireValue!.orcamento.cliente;
    _nome = TextEditingController(text: cliente.nome);
    _numero = TextEditingController(text: cliente.numero);
    _cpfCnpj = TextEditingController(text: cliente.cpfCnpj);
    _email = TextEditingController(text: cliente.email ?? '');
    _observacoes = TextEditingController(text: cliente.observacoes ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _numero.dispose();
    _cpfCnpj.dispose();
    _email.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _atualizar([String _ = '']) => ref
      .read(widget.provider.notifier)
      .atualizarCliente(
        nome: _nome.text,
        numero: _numero.text,
        cpfCnpj: _cpfCnpj.text,
        email: _email.text,
        observacoes: _observacoes.text,
      );

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            WizardCampo(
              rotulo: 'Nome do cliente',
              obrigatorio: true,
              child: TextFormField(
                key: const Key('campo-nome'),
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ex: João da Silva',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validarObrigatorio,
                onChanged: _atualizar,
              ),
            ),
            WizardCampo(
              rotulo: 'Número do cliente',
              obrigatorio: true,
              child: TextFormField(
                key: const Key('campo-numero'),
                controller: _numero,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: const [TelefoneInputFormatter()],
                decoration: const InputDecoration(
                  hintText: '(99) 99999-9999',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: validarTelefone,
                onChanged: _atualizar,
              ),
            ),
            WizardCampo(
              // "CPF/CNPJ", e não "CPF" como no Figma (D-10).
              rotulo: 'CPF/CNPJ do cliente',
              obrigatorio: true,
              child: TextFormField(
                key: const Key('campo-cpf-cnpj'),
                controller: _cpfCnpj,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: const [CpfCnpjInputFormatter()],
                decoration: const InputDecoration(
                  hintText: '123.456.789-00',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: validarCpfCnpj,
                onChanged: _atualizar,
              ),
            ),
            WizardCampo(
              rotulo: 'Email do cliente',
              child: TextFormField(
                key: const Key('campo-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'email@exemplo.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: validarEmail,
                onChanged: _atualizar,
              ),
            ),
            WizardCampo(
              rotulo: 'Observações',
              child: TextFormField(
                key: const Key('campo-observacoes'),
                controller: _observacoes,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Detalhes adicionais sobre o cliente...',
                ),
                onChanged: _atualizar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
