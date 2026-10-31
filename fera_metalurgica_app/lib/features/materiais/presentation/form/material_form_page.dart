import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/campo_dinheiro.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/validacao_material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/lista/alternar_situacao_material.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_controller.dart';
import 'package:fera_metalurgica_app/features/materiais/presentation/materiais_ui.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mensagem de quando se tenta trocar a unidade de um material em uso
/// (D-40).
const String mensagemUnidadeEmUso =
    'Este material já está em orçamentos. Para usar outra unidade, '
    'cadastre um material novo e inative este.';

/// Formulário de material: novo, ou edição do material [materialId].
///
/// Contrato (atalho "Cadastrar material" da V2-A):
/// `context.push<String>(AppRoutes.material())` volta com o id do material
/// salvo, ou `null` se o operador voltar sem salvar.
///
/// Num material que já está em orçamentos, a unidade não muda (D-40).
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
          // Ao inativar ou reativar, o provider recarrega: o formulário
          // continua com o valor anterior, sem voltar ao carregamento nem
          // perder o que foi digitado.
          : switch (ref.watch(materialPorIdProvider(id))) {
              AsyncValue(value: final Material material) => _MaterialForm(
                key: ValueKey(id),
                inicial: material,
              ),
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AsyncError() => const _Mensagem(
                'Não foi possível carregar o material.',
              ),
              _ => const _Mensagem('Material não encontrado.'),
            },
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
      ),
    ),
  );
}

class _MaterialForm extends ConsumerStatefulWidget {
  const _MaterialForm({this.inicial, super.key});

  final Material? inicial;

  @override
  ConsumerState<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends ConsumerState<_MaterialForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late UnidadeCobranca _unidade;
  Dinheiro? _preco;

  /// Erros de `validarMaterial` por `caminhoCampo`.
  Map<String, String> _erros = const {};
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    _nome = TextEditingController(text: inicial?.nome);
    _unidade = inicial?.unidade ?? UnidadeCobranca.m2;
    _preco = inicial?.precoReferencia;
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _limparErro(String campo) {
    if (!_erros.containsKey(campo)) return;
    setState(() => _erros = {..._erros}..remove(campo));
  }

  /// Troca a unidade, exceto num material salvo que já está em orçamentos
  /// (D-40): aí explica o que fazer e mantém a unidade.
  Future<void> _trocarUnidade(UnidadeCobranca nova) async {
    final inicial = widget.inicial;
    if (inicial != null && nova != inicial.unidade) {
      final bool emUso;
      try {
        emUso = await ref.read(materialEmUsoProvider(inicial.id).future);
      } on Object {
        _avisar('Não foi possível verificar se o material está em uso.');
        return;
      }
      if (!mounted) return;
      if (emUso) {
        await _avisarUnidadeEmUso();
        return;
      }
    }
    setState(() => _unidade = nova);
  }

  Future<void> _avisarUnidadeEmUso() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A unidade não pode mudar'),
      content: const Text(mensagemUnidadeEmUso),
      actions: [
        TextButton(
          // A cor primária sobre o fundo do diálogo não chega a 4,5:1
          // (D-25).
          style: TextButton.styleFrom(
            foregroundColor: context.colors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );

  Future<void> _salvar() async {
    // O campo de preço com texto inválido não chega a `_preco`: o `Form`
    // mostra o erro e para aqui.
    if (!(_form.currentState?.validate() ?? false)) return;
    final material = Material(
      id: widget.inicial?.id ?? gerarId(),
      nome: _nome.text.trim(),
      unidade: _unidade,
      precoReferencia: _preco ?? Dinheiro.zero,
      ativo: widget.inicial?.ativo ?? true,
    );
    final erros = {
      for (final erro in validarMaterial(material))
        erro.caminhoCampo: erro.mensagem,
      if (_preco == null) 'precoReferencia': 'Campo obrigatório',
    };
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
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
    final inicial = widget.inicial;
    // Observado para a consulta começar ao abrir e o aviso aparecer antes
    // de qualquer toque. AutoDispose: consulta de novo a cada abertura.
    final emUso =
        inicial != null &&
        (ref.watch(materialEmUsoProvider(inicial.id)).value ?? false);
    final dica = AppTextStyles.caption.copyWith(color: colors.textSecondary);

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                inicial == null ? 'Novo material' : 'Editar material',
                style: AppTextStyles.headline.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (inicial != null && !inicial.ativo)
                const StatusChip(label: 'Inativo'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FormCampo(
            rotulo: 'Nome',
            obrigatorio: true,
            child: TextField(
              key: const ValueKey('material-nome'),
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _limparErro('nome'),
              decoration: InputDecoration(
                hintText: 'Ex: Granito - variedade B - 2 cm',
                helperText:
                    'Identifique a variação que muda o preço: espécie, '
                    'acabamento, espessura.',
                helperMaxLines: 2,
                errorText: _erros['nome'],
              ),
            ),
          ),
          FormCampo(
            rotulo: 'Unidade de cobrança',
            obrigatorio: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<UnidadeCobranca>(
                  key: const ValueKey('material-unidade'),
                  showSelectedIcon: false,
                  segments: [
                    for (final unidade in UnidadeCobranca.values)
                      ButtonSegment(
                        value: unidade,
                        label: Text(unidade.simbolo),
                        tooltip: unidade.descricao,
                      ),
                  ],
                  selected: {_unidade},
                  onSelectionChanged: (selecao) =>
                      _trocarUnidade(selecao.single),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  emUso
                      ? mensagemUnidadeEmUso
                      : 'm² cobra pela área da peça; m³, pelo volume (com '
                            'a espessura).',
                  key: const ValueKey('material-unidade-dica'),
                  style: dica,
                ),
              ],
            ),
          ),
          CampoDinheiro(
            key: const ValueKey('material-preco'),
            rotulo: 'Preço de referência por ${_unidade.simbolo} *',
            valorInicial: inicial?.precoReferencia,
            errorText: _erros['precoReferencia'],
            onChanged: (valor) {
              _preco = valor;
              _limparErro('precoReferencia');
            },
          ),
          Text(
            'Sugerido ao escolher o material numa peça. O preço pode ser '
            'ajustado na peça sem mudar este cadastro.',
            style: dica,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Salvar material',
            icon: Icons.check,
            large: true,
            onPressed: _salvando ? null : _salvar,
          ),
          if (inicial != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedAppButton(
              label: inicial.ativo ? 'Inativar material' : 'Reativar material',
              icon: inicial.ativo
                  ? Icons.block_outlined
                  : Icons.settings_backup_restore,
              onPressed: _salvando
                  ? null
                  : () => alternarSituacaoMaterial(context, ref, inicial),
            ),
          ],
        ],
      ),
    );
  }
}
