import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/medidas.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Valor da opção "Outro" do tipo do serviço (D-20).
const String _outro = '__outro__';

/// Formulário de um item do orçamento (etapa 2, RF-22).
///
/// Sem [item], cria um item novo ("Adicionar Item"); com [item], edita esse
/// item ("Salvar Item" e "Cancelar"). Para limpar o formulário depois de
/// salvar, quem usa troca a `key`.
class ItemForm extends ConsumerStatefulWidget {
  /// Cria o formulário.
  const ItemForm({
    required this.onSalvar,
    this.item,
    this.onCancelar,
    super.key,
  });

  /// Item em edição, ou `null` para um item novo.
  final ItemOrcamento? item;

  /// Recebe o item preenchido e válido.
  final ValueChanged<ItemOrcamento> onSalvar;

  /// Sai da edição sem salvar.
  final VoidCallback? onCancelar;

  @override
  ConsumerState<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _outroTexto;
  late final TextEditingController _altura;
  late final TextEditingController _largura;
  late final TextEditingController _comprimento;
  late final TextEditingController _material;
  late final TextEditingController _especificacoes;
  late final TextEditingController _quantidade;

  /// Id do produto escolhido, [_outro] ou `null` (nada escolhido).
  String? _tipo;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _tipo = item == null ? null : (item.produtoId ?? _outro);
    _outroTexto = TextEditingController(
      text: item != null && item.produtoId == null ? item.tipoServico : '',
    );
    _altura = TextEditingController(text: _medidaTexto(item?.medidas.altura));
    _largura = TextEditingController(text: _medidaTexto(item?.medidas.largura));
    _comprimento = TextEditingController(
      text: _medidaTexto(item?.medidas.comprimento),
    );
    _material = TextEditingController(text: item?.materialPrincipal ?? '');
    _especificacoes = TextEditingController(text: item?.especificacoes ?? '');
    _quantidade = TextEditingController(text: '${item?.quantidade ?? 1}');
  }

  @override
  void dispose() {
    _outroTexto.dispose();
    _altura.dispose();
    _largura.dispose();
    _comprimento.dispose();
    _material.dispose();
    _especificacoes.dispose();
    _quantidade.dispose();
    super.dispose();
  }

  void _salvar(List<ProdutoCatalogo> produtos) {
    if (!_formKey.currentState!.validate()) return;
    final produto = produtos.where((p) => p.id == _tipo).firstOrNull;
    widget.onSalvar(
      ItemOrcamento(
        id: widget.item?.id ?? gerarId(),
        tipoServico: produto?.nome ?? _outroTexto.text.trim(),
        produtoId: produto?.id,
        medidas: Medidas(
          altura: _lerMedida(_altura.text),
          largura: _lerMedida(_largura.text),
          comprimento: _lerMedida(_comprimento.text),
        ),
        materialPrincipal: _textoOuNull(_material.text),
        especificacoes: _textoOuNull(_especificacoes.text),
        quantidade: int.parse(_quantidade.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final produtos =
        ref.watch(produtosCatalogoProvider).value ?? const <ProdutoCatalogo>[];
    final ids = {for (final p in produtos) p.id};
    final editando = widget.item != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizardCampo(
            rotulo: 'Tipo do serviço',
            obrigatorio: true,
            child: DropdownButtonFormField<String>(
              // Recria quando o catálogo carrega, para aplicar a seleção
              // inicial de um item em edição.
              key: ValueKey('tipo-servico-${ids.length}'),
              initialValue: _tipo == _outro || ids.contains(_tipo)
                  ? _tipo
                  : null,
              isExpanded: true,
              hint: const Text('Selecione um item'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.construction_outlined),
              ),
              items: [
                for (final produto in produtos)
                  DropdownMenuItem(
                    value: produto.id,
                    child: Text(produto.nome, overflow: TextOverflow.ellipsis),
                  ),
                const DropdownMenuItem(value: _outro, child: Text('Outro')),
              ],
              validator: (valor) => valor == null ? 'Campo obrigatório' : null,
              onChanged: (valor) => setState(() => _tipo = valor),
            ),
          ),
          if (_tipo == _outro)
            WizardCampo(
              rotulo: 'Descreva o serviço',
              obrigatorio: true,
              child: TextFormField(
                key: const Key('campo-outro-servico'),
                controller: _outroTexto,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex: Escada metálica',
                ),
                validator: validarObrigatorio,
              ),
            ),
          WizardCampo(
            rotulo: 'Medidas (Metros)',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CampoMedida(letra: 'A', controller: _altura),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _CampoMedida(letra: 'L', controller: _largura),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _CampoMedida(letra: 'C', controller: _comprimento),
                ),
              ],
            ),
          ),
          WizardCampo(
            rotulo: 'Material Principal',
            child: TextFormField(
              key: const Key('campo-material'),
              controller: _material,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex: Aço Carbono, Alumínio, Inox',
              ),
            ),
          ),
          WizardCampo(
            rotulo: 'Especificações Técnicas / Observações',
            child: TextFormField(
              key: const Key('campo-especificacoes'),
              controller: _especificacoes,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Descreva detalhes de acabamento, pintura, ou '
                    'necessidades específicas da instalação...',
              ),
            ),
          ),
          WizardCampo(
            rotulo: 'Quantidade',
            obrigatorio: true,
            child: TextFormField(
              key: const Key('campo-quantidade'),
              controller: _quantidade,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (valor) => (int.tryParse(valor ?? '') ?? 0) < 1
                  ? 'Informe pelo menos 1'
                  : null,
            ),
          ),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.xs,
            children: [
              if (editando)
                TextButton(
                  onPressed: widget.onCancelar,
                  child: const Text('Cancelar'),
                ),
              OutlinedAppButton(
                label: editando ? 'Salvar Item' : 'Adicionar Item',
                icon: editando ? Icons.check : Icons.add,
                onPressed: () => _salvar(produtos),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uma das medidas A, L ou C.
class _CampoMedida extends StatelessWidget {
  const _CampoMedida({required this.letra, required this.controller});

  final String letra;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key('campo-medida-$letra'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      decoration: InputDecoration(prefixText: '$letra  ', hintText: '0.00'),
      validator: (valor) {
        if (valor == null || valor.trim().isEmpty) return null;
        return _lerMedida(valor) == null ? 'Inválida' : null;
      },
    );
  }
}

/// Medida digitada, com vírgula ou ponto: `null` se vazia, inválida ou não
/// positiva.
double? _lerMedida(String texto) {
  final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
  return valor == null || valor <= 0 ? null : valor;
}

String _medidaTexto(double? medida) => medida == null ? '' : '$medida';

String? _textoOuNull(String texto) {
  final aparado = texto.trim();
  return aparado.isEmpty ? null : aparado;
}
