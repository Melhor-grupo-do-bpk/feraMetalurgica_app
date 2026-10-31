import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/validacao_empresa.dart';
import 'package:fera_metalurgica_app/features/empresa/presentation/empresa_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dados da empresa emitente (prompt §3.2), abertos por "Mais" e pelo
/// bloqueio de "Novo orçamento" sem empresa completa (D-38).
///
/// Salvar grava e, se houver para onde voltar, volta; senão fica na tela.
/// A tela não abre o wizard sozinha.
class EmpresaPage extends ConsumerWidget {
  /// Cria a tela.
  const EmpresaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppTopBar(onBack: context.canPop() ? () => context.pop() : null),
      body: switch (ref.watch(dadosEmpresaProvider)) {
        AsyncData(:final value) => _EmpresaForm(inicial: value),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Não foi possível carregar os dados da empresa.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedAppButton(
                  label: 'Tentar novamente',
                  icon: Icons.refresh,
                  onPressed: () => ref.invalidate(dadosEmpresaProvider),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Um campo do formulário: a chave (também do `ValueKey('empresa-$chave')`),
/// o caminho do erro em `validarEmpresa` e a aparência.
typedef _Campo = ({
  String chave,
  String caminho,
  String rotulo,
  bool obrigatorio,
  TextInputType teclado,
  List<TextInputFormatter> formatadores,
  TextCapitalization maiusculas,
  String? dica,
});

_Campo _campo(
  String chave,
  String rotulo, {
  String? caminho,
  bool obrigatorio = true,
  TextInputType teclado = TextInputType.text,
  List<TextInputFormatter> formatadores = const [],
  TextCapitalization maiusculas = TextCapitalization.words,
  String? dica,
}) => (
  chave: chave,
  caminho: caminho ?? chave,
  rotulo: rotulo,
  obrigatorio: obrigatorio,
  teclado: teclado,
  formatadores: formatadores,
  maiusculas: maiusculas,
  dica: dica,
);

final _Campo _nome = _campo(
  'nome',
  'Nome ou razão social',
  caminho: 'nomeRazaoSocial',
);
final _Campo _documento = _campo(
  'documento',
  'CPF/CNPJ',
  teclado: TextInputType.number,
  formatadores: const [CpfCnpjInputFormatter()],
  dica: '000.000.000-00 ou 00.000.000/0000-00',
);
final _Campo _telefone = _campo(
  'telefone',
  'Telefone',
  teclado: TextInputType.phone,
  formatadores: const [TelefoneInputFormatter()],
  dica: '(00) 00000-0000',
);
final _Campo _email = _campo(
  'email',
  'E-mail',
  obrigatorio: false,
  teclado: TextInputType.emailAddress,
  maiusculas: TextCapitalization.none,
  dica: 'contato@empresa.com.br',
);
final _Campo _cep = _campo(
  'cep',
  'CEP',
  caminho: 'endereco.cep',
  obrigatorio: false,
  teclado: TextInputType.number,
  formatadores: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
  ],
  dica: '8 dígitos',
);
final _Campo _logradouro = _campo(
  'logradouro',
  'Logradouro',
  caminho: 'endereco.logradouro',
  dica: 'Rua, avenida...',
);
final _Campo _numero = _campo(
  'numero',
  'Número',
  caminho: 'endereco.numero',
  maiusculas: TextCapitalization.none,
  dica: 'Ou s/n',
);
final _Campo _complemento = _campo(
  'complemento',
  'Complemento',
  caminho: 'endereco.complemento',
  obrigatorio: false,
  maiusculas: TextCapitalization.sentences,
);
final _Campo _bairro = _campo('bairro', 'Bairro', caminho: 'endereco.bairro');
final _Campo _cidade = _campo('cidade', 'Cidade', caminho: 'endereco.cidade');
final _Campo _uf = _campo(
  'uf',
  'UF',
  caminho: 'endereco.uf',
  maiusculas: TextCapitalization.characters,
  formatadores: [
    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
    LengthLimitingTextInputFormatter(2),
    const MaiusculasInputFormatter(),
  ],
  dica: 'Ex: RS',
);

/// Todos os campos, na ordem da tela (a do primeiro erro ao rolar).
final List<_Campo> _campos = [
  _nome,
  _documento,
  _telefone,
  _email,
  _cep,
  _logradouro,
  _numero,
  _complemento,
  _bairro,
  _cidade,
  _uf,
];

class _EmpresaForm extends ConsumerStatefulWidget {
  const _EmpresaForm({this.inicial});

  final Empresa? inicial;

  @override
  ConsumerState<_EmpresaForm> createState() => _EmpresaFormState();
}

class _EmpresaFormState extends ConsumerState<_EmpresaForm> {
  late final Map<String, TextEditingController> _textos;
  final Map<String, GlobalKey> _chaves = {
    for (final campo in _campos) campo.chave: GlobalKey(),
  };

  /// Erros de `validarEmpresa` por `caminhoCampo`.
  Map<String, String> _erros = const {};
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.inicial;
    final valores = <String, String?>{
      'nome': e?.nomeRazaoSocial,
      'documento': e?.documento.formatado,
      'telefone': e == null ? null : formatarTelefone(e.telefone),
      'email': e?.email,
      'cep': e?.endereco.cep,
      'logradouro': e?.endereco.logradouro,
      'numero': e?.endereco.numero,
      'complemento': e?.endereco.complemento,
      'bairro': e?.endereco.bairro,
      'cidade': e?.endereco.cidade,
      'uf': e?.endereco.uf,
    };
    _textos = {
      for (final campo in _campos)
        campo.chave: TextEditingController(text: valores[campo.chave]),
    };
  }

  @override
  void dispose() {
    for (final texto in _textos.values) {
      texto.dispose();
    }
    super.dispose();
  }

  String _texto(_Campo campo) => _textos[campo.chave]!.text.trim();

  String? _opcional(_Campo campo) {
    final texto = _texto(campo);
    return texto.isEmpty ? null : texto;
  }

  void _limparErro(_Campo campo) {
    if (!_erros.containsKey(campo.caminho)) return;
    setState(() => _erros = {..._erros}..remove(campo.caminho));
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    final empresa = Empresa(
      id: widget.inicial?.id ?? gerarId(),
      nomeRazaoSocial: _texto(_nome),
      documento: Documento.deTexto(_texto(_documento)),
      telefone: _texto(_telefone),
      email: _opcional(_email),
      endereco: Endereco(
        logradouro: _texto(_logradouro),
        numero: _texto(_numero),
        complemento: _opcional(_complemento),
        bairro: _texto(_bairro),
        cidade: _texto(_cidade),
        uf: _texto(_uf).toUpperCase(),
        cep: _opcional(_cep),
      ),
    );
    final erros = {
      for (final erro in validarEmpresa(empresa))
        erro.caminhoCampo: erro.mensagem,
    };
    setState(() => _erros = erros);
    if (erros.isNotEmpty) {
      _rolarAte(_campos.firstWhere((c) => erros.containsKey(c.caminho)));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    void avisar(String mensagem) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
    setState(() => _salvando = true);
    try {
      await ref.read(dadosEmpresaProvider.notifier).salvar(empresa);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        setState(() => _salvando = false);
      }
      avisar('Dados da empresa salvos.');
    } on Object {
      if (!mounted) return;
      setState(() => _salvando = false);
      avisar('Não foi possível salvar os dados da empresa.');
    }
  }

  void _rolarAte(_Campo campo) {
    final contexto = _chaves[campo.chave]!.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 250),
      alignment: 0.1,
    );
  }

  Widget _construir(_Campo campo) => FormCampo(
    key: _chaves[campo.chave],
    rotulo: campo.rotulo,
    obrigatorio: campo.obrigatorio,
    child: TextField(
      key: ValueKey('empresa-${campo.chave}'),
      controller: _textos[campo.chave],
      keyboardType: campo.teclado,
      inputFormatters: campo.formatadores,
      textCapitalization: campo.maiusculas,
      autocorrect: campo.teclado == TextInputType.text,
      textInputAction: TextInputAction.next,
      onChanged: (_) => _limparErro(campo),
      decoration: InputDecoration(
        hintText: campo.dica,
        errorText: _erros[campo.caminho],
        errorMaxLines: 2,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final completa = widget.inicial?.estaCompleta ?? false;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Dados da empresa',
          style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          completa
              ? 'Emitente dos novos orçamentos. Os orçamentos já salvos '
                    'guardam os dados da época e não mudam.'
              : 'Preencha os campos obrigatórios (*) para liberar o "Novo '
                    'orçamento".',
          key: const ValueKey('empresa-orientacao'),
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          titulo: 'Identificação',
          icone: Icons.business_outlined,
          child: Column(children: [_construir(_nome), _construir(_documento)]),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Contato',
          icone: Icons.phone_outlined,
          child: Column(children: [_construir(_telefone), _construir(_email)]),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Endereço',
          icone: Icons.place_outlined,
          child: Column(
            children: [
              _construir(_cep),
              _construir(_logradouro),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _construir(_numero)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 2, child: _construir(_complemento)),
                ],
              ),
              _construir(_bairro),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _construir(_cidade)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _construir(_uf)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
