import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/aviso_inline.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quantos clientes a busca mostra de uma vez.
const int _maximoResultados = 5;

/// Etapa 1, cliente (prompt §3.3): busca por nome, celular ou documento e
/// a cópia editável do cliente na sessão.
///
/// Selecionar um cliente preenche o formulário; cada mudança manda a cópia
/// completa para o controller (`atualizarCliente`). O cadastro só é criado
/// ou atualizado ao salvar o orçamento, pelo documento normalizado.
///
/// Se o documento ficar diferente do cliente selecionado, a identidade é
/// resolvida de novo (`clientePorDocumentoProvider`) e um aviso diz se é
/// outro cadastro (com "Usar cadastro") ou um cadastro novo. Os erros de
/// cada campo vêm do controller ao avançar.
class EtapaCliente extends ConsumerStatefulWidget {
  /// Cria a etapa.
  const EtapaCliente({super.key});

  @override
  ConsumerState<EtapaCliente> createState() => _EtapaClienteState();
}

class _EtapaClienteState extends ConsumerState<EtapaCliente> {
  final TextEditingController _busca = TextEditingController();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _documento = TextEditingController();
  final TextEditingController _celular = TextEditingController();
  final TextEditingController _logradouro = TextEditingController();
  final TextEditingController _numero = TextEditingController();
  final TextEditingController _complemento = TextEditingController();
  final TextEditingController _bairro = TextEditingController();
  final TextEditingController _cidade = TextEditingController();
  final TextEditingController _uf = TextEditingController();
  final TextEditingController _cep = TextEditingController();

  /// Cliente de referência: o selecionado na busca (ou o da sessão, na
  /// edição). `null` num cliente digitado do zero.
  ClienteSnapshot? _referencia;

  List<TextEditingController> get _campos => [
    _nome,
    _documento,
    _celular,
    _logradouro,
    _numero,
    _complemento,
    _bairro,
    _cidade,
    _uf,
    _cep,
  ];

  @override
  void initState() {
    super.initState();
    final cliente = ref.read(orcamentoControllerProvider).edicao?.cliente;
    if (cliente != null) _preencher(cliente);
  }

  @override
  void dispose() {
    _busca.dispose();
    for (final campo in _campos) {
      campo.dispose();
    }
    super.dispose();
  }

  Documento get _documentoDigitado => Documento.deTexto(_documento.text);

  /// Se o documento digitado é diferente do cliente de referência.
  bool get _documentoMudou {
    final referencia = _referencia;
    return referencia != null && referencia.documento != _documentoDigitado;
  }

  void _preencher(ClienteSnapshot cliente) {
    _referencia = cliente;
    final endereco = cliente.endereco;
    _nome.text = cliente.nome;
    _documento.text = cliente.documento.formatado;
    _celular.text = formatarTelefone(cliente.celular);
    _logradouro.text = endereco.logradouro;
    _numero.text = endereco.numero;
    _complemento.text = endereco.complemento ?? '';
    _bairro.text = endereco.bairro;
    _cidade.text = endereco.cidade;
    _uf.text = endereco.uf;
    _cep.text = endereco.cep ?? '';
  }

  /// Escolhe [cliente] do cadastro: preenche a cópia e limpa a busca.
  void _selecionar(Cliente cliente) {
    setState(() {
      _busca.clear();
      _preencher(cliente.gerarSnapshot());
    });
    FocusScope.of(context).unfocus();
    ref.read(orcamentoControllerProvider.notifier).selecionarCliente(cliente);
  }

  String? _textoOuNulo(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isEmpty ? null : texto;
  }

  /// Manda a cópia do formulário para a sessão. Antes do primeiro dado,
  /// a sessão continua sem cliente.
  void _enviar() {
    setState(() {});
    final vazio = _campos.every((c) => c.text.trim().isEmpty);
    final controller = ref.read(orcamentoControllerProvider.notifier);
    if (vazio &&
        ref.read(orcamentoControllerProvider).edicao?.cliente == null) {
      return;
    }
    controller.atualizarCliente(
      ClienteSnapshot(
        nome: _nome.text.trim(),
        documento: _documentoDigitado,
        celular: _celular.text.trim(),
        endereco: Endereco(
          logradouro: _logradouro.text.trim(),
          numero: _numero.text.trim(),
          complemento: _textoOuNulo(_complemento),
          bairro: _bairro.text.trim(),
          cidade: _cidade.text.trim(),
          uf: _uf.text.trim(),
          cep: _textoOuNulo(_cep),
        ),
        // Outro documento é outra identidade: a origem antiga não vale.
        clienteOrigemId: _documentoMudou ? null : _referencia?.clienteOrigemId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final erros = ref.watch(orcamentoControllerProvider).erros;
    String? erro(String campo) => erros
        .where((e) => e.caminhoCampo == 'cliente.$campo')
        .firstOrNull
        ?.mensagem;
    final semCliente = erros.any((e) => e.caminhoCampo == 'cliente');

    Widget campo(
      String chave,
      String rotulo,
      TextEditingController controller, {
      bool obrigatorio = true,
      String? caminho,
      TextInputType? teclado,
      List<TextInputFormatter>? formatadores,
      TextCapitalization capitalizacao = TextCapitalization.words,
      String? dica,
    }) => FormCampo(
      rotulo: rotulo,
      obrigatorio: obrigatorio,
      child: TextFormField(
        key: ValueKey('cliente-$chave'),
        controller: controller,
        keyboardType: teclado,
        inputFormatters: formatadores,
        textCapitalization: capitalizacao,
        decoration: InputDecoration(
          hintText: dica,
          errorText: erro(caminho ?? chave),
        ),
        onChanged: (_) => _enviar(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          titulo: 'Buscar cliente',
          icone: Icons.search,
          child: _Busca(controller: _busca, onSelecionar: _selecionar),
        ),
        const SizedBox(height: AppSpacing.md),
        if (semCliente) ...[
          Text(
            'Busque um cliente cadastrado ou preencha os dados abaixo.',
            style: AppTextStyles.body.copyWith(color: colors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SectionCard(
          titulo: 'Dados do cliente',
          icone: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Os dados ficam no orçamento. O cadastro do cliente só é '
                'criado ou atualizado ao salvar.',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              campo('nome', 'Nome ou razão social', _nome),
              campo(
                'documento',
                'CPF/CNPJ',
                _documento,
                teclado: TextInputType.number,
                formatadores: const [CpfCnpjInputFormatter()],
                capitalizacao: TextCapitalization.none,
              ),
              _AvisoDocumento(
                documento: _documentoDigitado,
                referencia: _referencia,
                documentoMudou: _documentoMudou,
                onUsarCadastro: _selecionar,
              ),
              campo(
                'celular',
                'Celular (WhatsApp)',
                _celular,
                teclado: TextInputType.phone,
                formatadores: const [TelefoneInputFormatter()],
                capitalizacao: TextCapitalization.none,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Endereço',
          icone: Icons.location_on_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              campo(
                'logradouro',
                'Logradouro',
                _logradouro,
                caminho: 'endereco.logradouro',
                dica: 'Rua, avenida...',
              ),
              campo(
                'numero',
                'Número',
                _numero,
                caminho: 'endereco.numero',
                dica: 'Ex: 123 ou s/n',
                capitalizacao: TextCapitalization.none,
              ),
              campo(
                'complemento',
                'Complemento',
                _complemento,
                obrigatorio: false,
                caminho: 'endereco.complemento',
                capitalizacao: TextCapitalization.sentences,
              ),
              campo('bairro', 'Bairro', _bairro, caminho: 'endereco.bairro'),
              campo('cidade', 'Cidade', _cidade, caminho: 'endereco.cidade'),
              campo(
                'uf',
                'UF',
                _uf,
                caminho: 'endereco.uf',
                dica: 'Ex: SP',
                capitalizacao: TextCapitalization.characters,
                formatadores: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                  LengthLimitingTextInputFormatter(2),
                  const MaiusculasInputFormatter(),
                ],
              ),
              campo(
                'cep',
                'CEP',
                _cep,
                obrigatorio: false,
                caminho: 'endereco.cep',
                dica: 'Só os 8 números',
                teclado: TextInputType.number,
                formatadores: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Campo de busca e a lista de clientes encontrados.
class _Busca extends ConsumerStatefulWidget {
  const _Busca({required this.controller, required this.onSelecionar});

  final TextEditingController controller;
  final ValueChanged<Cliente> onSelecionar;

  @override
  ConsumerState<_Busca> createState() => _BuscaState();
}

class _BuscaState extends ConsumerState<_Busca> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final termo = widget.controller.text.trim();
    final resultado = termo.isEmpty
        ? null
        : ref.watch(buscaClientesProvider(termo));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('wizard-busca-cliente'),
          controller: widget.controller,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Nome, celular ou CPF/CNPJ',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        switch (resultado) {
          null => const SizedBox.shrink(),
          AsyncValue(value: final clientes?) when clientes.isEmpty => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Nenhum cliente encontrado. Preencha os dados abaixo para '
              'cadastrar ao salvar.',
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
          ),
          // O card não é um `Material`: sem este, o toque do ListTile não
          // aparece.
          AsyncValue(value: final clientes?) => Material(
            key: const ValueKey('wizard-resultados-cliente'),
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (final cliente in clientes.take(_maximoResultados))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      cliente.nome,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${cliente.documento.formatado} • '
                      '${formatarTelefone(cliente.celular)}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colors.textMuted,
                    ),
                    onTap: () => widget.onSelecionar(cliente),
                  ),
              ],
            ),
          ),
          AsyncError() => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Não foi possível buscar os clientes.',
              style: AppTextStyles.body.copyWith(color: colors.error),
            ),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

/// Aviso de identidade pelo documento (prompt §3.3): com o documento
/// completo, diz se ele é de outro cadastro (os dados digitados vão
/// atualizá-lo ao salvar) ou, se mudou em relação ao cliente selecionado,
/// que será criado um cadastro novo.
class _AvisoDocumento extends ConsumerWidget {
  const _AvisoDocumento({
    required this.documento,
    required this.referencia,
    required this.documentoMudou,
    required this.onUsarCadastro,
  });

  final Documento documento;
  final ClienteSnapshot? referencia;
  final bool documentoMudou;
  final ValueChanged<Cliente> onUsarCadastro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digitos = documento.valorNormalizado.length;
    if (digitos != 11 && digitos != 14) return const SizedBox.shrink();
    final referencia = this.referencia;
    final cadastro = ref.watch(clientePorDocumentoProvider(documento)).value;
    final ehOutroCadastro =
        cadastro != null &&
        (referencia == null || cadastro.id != referencia.clienteOrigemId);

    if (ehOutroCadastro) {
      return _Aviso(
        key: const ValueKey('cliente-aviso-outro-cadastro'),
        texto:
            'Este documento é do cadastro de ${cadastro.nome}. Ao salvar, os '
            'dados desse cadastro serão atualizados com os digitados aqui.',
        acao: OutlinedAppButton(
          label: 'Usar cadastro',
          icon: Icons.person_search_outlined,
          onPressed: () => onUsarCadastro(cadastro),
        ),
      );
    }
    if (documentoMudou && cadastro == null && referencia != null) {
      return _Aviso(
        key: const ValueKey('cliente-aviso-cadastro-novo'),
        texto:
            'O documento mudou e pode ser de outra pessoa. Nenhum cliente tem '
            'este documento: ao salvar, será criado um cadastro novo, e o de '
            '${referencia.nome} não muda.',
      );
    }
    return const SizedBox.shrink();
  }
}

/// Aviso da etapa 1, com o espaço abaixo dele.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.acao, super.key});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: AvisoInline(texto: texto, acao: acao),
  );
}
