import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/campo_dinheiro.dart';
import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/aviso_total_zero.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/linha_valor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 3, valores (prompt §4 e §6): adicionais, desconto, validade e
/// observações, com o total geral calculado (não editável).
///
/// Cada mudança manda o estado completo do formulário para o controller
/// (`atualizarValores`). Texto que não é um valor válido não chega ao
/// controller: o campo mostra o erro, e o `Form` da página impede avançar.
/// Os erros de regra (outros sem descrição, desconto maior que o subtotal,
/// validade) vêm do controller ao avançar, no campo de cada um.
class EtapaValores extends ConsumerStatefulWidget {
  /// Cria a etapa.
  const EtapaValores({super.key});

  @override
  ConsumerState<EtapaValores> createState() => _EtapaValoresState();
}

class _EtapaValoresState extends ConsumerState<EtapaValores> {
  late Dinheiro _insumos;
  late Dinheiro _impostos;
  late Dinheiro _combustivel;
  late Dinheiro _outros;
  late Dinheiro _desconto;
  late final TextEditingController _outrosDescricao;
  late final TextEditingController _validade;
  late final TextEditingController _observacoes;

  @override
  void initState() {
    super.initState();
    final edicao = ref.read(orcamentoControllerProvider).edicao!;
    _insumos = edicao.insumos;
    _impostos = edicao.impostos;
    _combustivel = edicao.combustivel;
    _outros = edicao.outros;
    _desconto = edicao.desconto;
    _outrosDescricao = TextEditingController(text: edicao.outrosDescricao);
    _validade = TextEditingController(
      text: edicao.validadeDias?.toString() ?? '',
    );
    _observacoes = TextEditingController(text: edicao.observacoes);
  }

  @override
  void dispose() {
    _outrosDescricao.dispose();
    _validade.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  int? get _validadeDias => int.tryParse(_validade.text);

  String? _textoOuNulo(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isEmpty ? null : texto;
  }

  void _enviar() => ref
      .read(orcamentoControllerProvider.notifier)
      .atualizarValores(
        insumos: _insumos,
        impostos: _impostos,
        combustivel: _combustivel,
        outros: _outros,
        desconto: _desconto,
        outrosDescricao: _textoOuNulo(_outrosDescricao),
        validadeDias: _validadeDias,
        observacoes: _textoOuNulo(_observacoes),
      );

  /// Atualiza um valor em dinheiro; o campo vazio (`null`) vale zero.
  ValueChanged<Dinheiro?> _aoMudar(void Function(Dinheiro) atribuir) =>
      (valor) {
        setState(() => atribuir(valor ?? Dinheiro.zero));
        _enviar();
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final estado = ref.watch(orcamentoControllerProvider);
    final resumo = estado.resumo;
    final agora = ref.watch(agoraProvider);
    final dias = _validadeDias;
    final limite = dias == null || dias < 1
        ? null
        : DateTime(agora.year, agora.month, agora.day + dias);

    String? erro(String campo) => estado.erros
        .where((e) => e.caminhoCampo == campo)
        .firstOrNull
        ?.mensagem;

    Dinheiro? inicial(Dinheiro valor) => valor.ehZero ? null : valor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'O preço base já cobre a fabricação de cada produto. Lance aqui só '
          'as despesas do orçamento inteiro, sem repetir o que já está no '
          'preço base.',
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoDinheiro(
          key: const ValueKey('valores-insumos'),
          rotulo: 'Insumos',
          valorInicial: inicial(_insumos),
          onChanged: _aoMudar((v) => _insumos = v),
          errorText: erro('insumos'),
        ),
        CampoDinheiro(
          key: const ValueKey('valores-impostos'),
          rotulo: 'Impostos',
          valorInicial: inicial(_impostos),
          onChanged: _aoMudar((v) => _impostos = v),
          errorText: erro('impostos'),
        ),
        CampoDinheiro(
          key: const ValueKey('valores-combustivel'),
          rotulo: 'Combustível',
          valorInicial: inicial(_combustivel),
          onChanged: _aoMudar((v) => _combustivel = v),
          errorText: erro('combustivel'),
        ),
        CampoDinheiro(
          key: const ValueKey('valores-outros'),
          rotulo: 'Outros',
          valorInicial: inicial(_outros),
          onChanged: _aoMudar((v) => _outros = v),
          errorText: erro('outros'),
        ),
        FormCampo(
          rotulo: 'Descrição de outros',
          obrigatorio: _outros.ehPositivo,
          child: TextFormField(
            key: const ValueKey('valores-outros-descricao'),
            controller: _outrosDescricao,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ex: frete, instalação',
              errorText: erro('outrosDescricao'),
            ),
            onChanged: (_) => _enviar(),
          ),
        ),
        CampoDinheiro(
          key: const ValueKey('valores-desconto'),
          rotulo: 'Desconto',
          valorInicial: inicial(_desconto),
          onChanged: _aoMudar((v) => _desconto = v),
          errorText: erro('desconto'),
        ),
        FormCampo(
          rotulo: 'Validade (dias corridos)',
          child: TextFormField(
            key: const ValueKey('valores-validade'),
            controller: _validade,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: 'Opcional',
              errorText: erro('validadeDias'),
              helperText: limite == null
                  ? null
                  : 'Válido até ${formatarData(limite)}',
            ),
            onChanged: (_) {
              setState(() {});
              _enviar();
            },
          ),
        ),
        FormCampo(
          rotulo: 'Observações',
          child: TextFormField(
            key: const ValueKey('valores-observacoes'),
            controller: _observacoes,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Opcional'),
            onChanged: (_) => _enviar(),
          ),
        ),
        SectionCard(
          titulo: 'Total',
          icone: Icons.calculate_outlined,
          child: resumo == null
              ? Text(
                  'Corrija os valores para ver o total geral.',
                  style: AppTextStyles.body.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinhaValor(
                      rotulo: 'Total dos produtos',
                      valor: resumo.totalProdutos.formatado,
                    ),
                    LinhaValor(
                      rotulo: 'Adicionais',
                      valor: resumo.totalAdicionais.formatado,
                    ),
                    LinhaValor(
                      rotulo: 'Subtotal',
                      valor: resumo.subtotal.formatado,
                    ),
                    LinhaValor(
                      rotulo: 'Desconto',
                      valor: '− ${resumo.desconto.formatado}',
                    ),
                    Divider(height: AppSpacing.md, color: colors.border),
                    LinhaValor(
                      key: const ValueKey('valores-total-geral'),
                      rotulo: 'Total geral',
                      valor: resumo.totalGeral.formatado,
                      destaque: true,
                    ),
                    if (resumo.totalGeralZero) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const AvisoTotalZero(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
