import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/validacao_material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_ui.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulário de material: novo, ou edição do material [materialId].
///
/// Contrato (atalho "Cadastrar material" da V2-A): ao salvar, volta com o
/// id do material salvo (`context.pop(id)`).
///
/// Stub da F2: nome, unidade e preço de referência, com a validação do
/// domínio.
// TODO(V2-C): acabamento e a orientação de não trocar a unidade de um
// material já usado (prompt §3.1).
class MaterialFormPage extends ConsumerWidget {
  /// Cria o formulário. Com [materialId], edita o material existente.
  const MaterialFormPage({this.materialId, super.key});

  /// Material em edição, ou `null` para um material novo.
  final String? materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = materialId;
    return Scaffold(
      appBar: AppTopBar(onBack: () => context.pop()),
      body: id == null
          ? const _MaterialForm()
          : switch (ref.watch(materialPorIdProvider(id))) {
              AsyncData(value: final Material material) => _MaterialForm(
                inicial: material,
              ),
              AsyncData() => const Center(
                child: Text('Material não encontrado.'),
              ),
              AsyncError() => const Center(
                child: Text('Não foi possível carregar o material.'),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
    );
  }
}

class _MaterialForm extends ConsumerStatefulWidget {
  const _MaterialForm({this.inicial});

  final Material? inicial;

  @override
  ConsumerState<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends ConsumerState<_MaterialForm> {
  late final TextEditingController _nome;
  late final TextEditingController _preco;
  late UnidadeCobranca _unidade;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    _nome = TextEditingController(text: inicial?.nome);
    _preco = TextEditingController(
      text: inicial?.precoReferencia.formatadoSemSimbolo,
    );
    _unidade = inicial?.unidade ?? UnidadeCobranca.m2;
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final preco = Dinheiro.tryParse(_preco.text);
    if (preco == null) {
      _avisar('Informe o preço de referência');
      return;
    }
    final material = Material(
      id: widget.inicial?.id ?? gerarId(),
      nome: _nome.text.trim(),
      unidade: _unidade,
      precoReferencia: preco,
      ativo: widget.inicial?.ativo ?? true,
    );
    final erros = validarMaterial(material);
    if (erros.isNotEmpty) {
      _avisar(erros.first.mensagem);
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref.read(materiaisProvider.notifier).salvar(material);
      if (mounted) context.pop(material.id);
    } on Object {
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Não foi possível salvar o material.');
    }
  }

  void _avisar(String mensagem) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          widget.inicial == null ? 'Novo material' : 'Editar material',
          style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const ValueKey('material-nome'),
          controller: _nome,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<UnidadeCobranca>(
          key: const ValueKey('material-unidade'),
          initialValue: _unidade,
          decoration: const InputDecoration(labelText: 'Unidade'),
          items: [
            for (final unidade in UnidadeCobranca.values)
              DropdownMenuItem(value: unidade, child: Text(unidade.simbolo)),
          ],
          onChanged: (unidade) =>
              setState(() => _unidade = unidade ?? _unidade),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('material-preco'),
          controller: _preco,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: r'Preço de referência (R$)',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Salvar material',
          icon: Icons.check,
          large: true,
          onPressed: _salvando ? null : _salvar,
        ),
      ],
    );
  }
}
