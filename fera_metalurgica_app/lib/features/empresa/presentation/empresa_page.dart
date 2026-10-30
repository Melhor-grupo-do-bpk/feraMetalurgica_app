import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/validacao_empresa.dart';
import 'package:fera_metalurgica_app/features/empresa/presentation/empresa_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dados da empresa emitente (prompt §3.2), abertos por "Mais" e pelo
/// bloqueio de "Novo orçamento" sem empresa completa.
///
/// Versão mínima da F2: os campos do cadastro, a validação do domínio e
/// salvar, para liberar o orçamento numa instalação nova.
// TODO(V2-C): acabamento (máscaras, campos agrupados, mensagens por campo).
class EmpresaPage extends ConsumerWidget {
  /// Cria a tela.
  const EmpresaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(onBack: context.canPop() ? () => context.pop() : null),
      body: switch (ref.watch(dadosEmpresaProvider)) {
        AsyncData(:final value) => _EmpresaForm(inicial: value),
        AsyncError() => const Center(
          child: Text('Não foi possível carregar os dados da empresa.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EmpresaForm extends ConsumerStatefulWidget {
  const _EmpresaForm({this.inicial});

  final Empresa? inicial;

  @override
  ConsumerState<_EmpresaForm> createState() => _EmpresaFormState();
}

class _EmpresaFormState extends ConsumerState<_EmpresaForm> {
  late final Map<String, TextEditingController> _campos;
  bool _salvando = false;

  static const Map<String, String> _rotulos = {
    'nome': 'Nome ou razão social',
    'documento': 'CPF/CNPJ',
    'telefone': 'Telefone',
    'email': 'E-mail (opcional)',
    'logradouro': 'Logradouro',
    'numero': 'Número',
    'complemento': 'Complemento (opcional)',
    'bairro': 'Bairro',
    'cidade': 'Cidade',
    'uf': 'UF',
    'cep': 'CEP (opcional)',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.inicial;
    final valores = <String, String?>{
      'nome': e?.nomeRazaoSocial,
      'documento': e?.documento.formatado,
      'telefone': e?.telefone,
      'email': e?.email,
      'logradouro': e?.endereco.logradouro,
      'numero': e?.endereco.numero,
      'complemento': e?.endereco.complemento,
      'bairro': e?.endereco.bairro,
      'cidade': e?.endereco.cidade,
      'uf': e?.endereco.uf,
      'cep': e?.endereco.cep,
    };
    _campos = {
      for (final chave in _rotulos.keys)
        chave: TextEditingController(text: valores[chave]),
    };
  }

  @override
  void dispose() {
    for (final campo in _campos.values) {
      campo.dispose();
    }
    super.dispose();
  }

  String _texto(String chave) => _campos[chave]!.text.trim();

  String? _opcional(String chave) {
    final texto = _texto(chave);
    return texto.isEmpty ? null : texto;
  }

  Future<void> _salvar() async {
    final cep = somenteDigitos(_texto('cep'));
    final empresa = Empresa(
      id: widget.inicial?.id ?? gerarId(),
      nomeRazaoSocial: _texto('nome'),
      documento: Documento.deTexto(_texto('documento')),
      telefone: _texto('telefone'),
      email: _opcional('email'),
      endereco: Endereco(
        logradouro: _texto('logradouro'),
        numero: _texto('numero'),
        complemento: _opcional('complemento'),
        bairro: _texto('bairro'),
        cidade: _texto('cidade'),
        uf: _texto('uf').toUpperCase(),
        cep: cep.isEmpty ? null : cep,
      ),
    );
    final erros = validarEmpresa(empresa);
    if (erros.isNotEmpty) {
      _avisar(erros.first.mensagem);
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref.read(dadosEmpresaProvider.notifier).salvar(empresa);
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Dados da empresa salvos.');
    } on Object {
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Não foi possível salvar os dados da empresa.');
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
          'Dados da empresa',
          style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Obrigatórios para criar orçamentos.',
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final MapEntry(key: chave, value: rotulo) in _rotulos.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextField(
              key: ValueKey('empresa-$chave'),
              controller: _campos[chave],
              decoration: InputDecoration(labelText: rotulo),
            ),
          ),
        PrimaryButton(
          label: 'Salvar dados',
          icon: Icons.check,
          large: true,
          onPressed: _salvando ? null : _salvar,
        ),
      ],
    );
  }
}
