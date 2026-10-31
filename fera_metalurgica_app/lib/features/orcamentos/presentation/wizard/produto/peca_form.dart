import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/confirmar_acao.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/validacao_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/aviso_inline.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/campo_texto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/linha_resumo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/rascunho_produto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/seletor_material.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Campos do formulário da peça, para os erros.
enum _CampoPeca {
  descricao,
  material,
  preco,
  comprimento,
  largura,
  espessura,
  quantidade,
}

/// Caminho do `ErroValidacao` de `validarPeca` → campo do formulário.
const Map<String, _CampoPeca> _campoDoCaminho = {
  'descricao': _CampoPeca.descricao,
  'material.nome': _CampoPeca.material,
  'material.precoAplicado': _CampoPeca.preco,
  'quantidadePorProduto': _CampoPeca.quantidade,
  'comprimentoCm': _CampoPeca.comprimento,
  'larguraCm': _CampoPeca.largura,
  'espessuraCm': _CampoPeca.espessura,
};

/// Formulário de uma peça do produto em montagem (prompt §4): descrição,
/// material (só ativos, com atalho para cadastrar), preço aplicado copiado
/// e editável, medidas em cm, quantidade por produto e observações, com o
/// resumo ao vivo da `CalculadoraOrcamento`.
///
/// Recomeça limpo a cada peça aceita: a etapa troca a `key` pela
/// `versaoFormularioPeca` do rascunho.
class PecaForm extends ConsumerStatefulWidget {
  /// Cria o formulário; com [inicial], edita essa peça do rascunho.
  const PecaForm({this.inicial, super.key});

  /// Peça em edição, ou `null` para uma peça nova.
  final PecaOrcamento? inicial;

  @override
  ConsumerState<PecaForm> createState() => _PecaFormState();
}

class _PecaFormState extends ConsumerState<PecaForm> {
  late final String _id;
  late final TextEditingController _descricao;
  late final TextEditingController _preco;
  late final TextEditingController _comprimento;
  late final TextEditingController _largura;
  late final TextEditingController _espessura;
  late final TextEditingController _quantidade;
  late final TextEditingController _observacoes;

  /// Material copiado; o preço aplicado vem do campo [_preco].
  MaterialSnapshot? _material;

  /// A unidade mudou com medidas preenchidas: "Adicionar peça" espera o
  /// operador editar uma medida ou tocar em "Medidas conferidas".
  bool _medidasARevisar = false;

  /// Se o operador já tentou aceitar a peça (só então os erros aparecem).
  bool _tentou = false;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    _id = inicial?.id ?? gerarId();
    _material = inicial?.material;
    _descricao = TextEditingController(text: inicial?.descricao);
    _preco = TextEditingController(
      text: inicial?.material.precoAplicado.formatadoSemSimbolo,
    );
    _comprimento = TextEditingController(
      text: inicial?.comprimentoCm.formatada,
    );
    _largura = TextEditingController(text: inicial?.larguraCm.formatada);
    _espessura = TextEditingController(text: inicial?.espessuraCm?.formatada);
    _quantidade = TextEditingController(
      text: '${inicial?.quantidadePorProduto ?? 1}',
    );
    _observacoes = TextEditingController(text: inicial?.observacoes);
  }

  @override
  void dispose() {
    for (final controller in [
      _descricao,
      _preco,
      _comprimento,
      _largura,
      _espessura,
      _quantidade,
      _observacoes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  RascunhoProduto get _rascunho => ref.read(rascunhoProdutoProvider.notifier);

  void _alterou() {
    _rascunho.marcarAlterado(naPeca: true);
    setState(() {});
  }

  void _alterouMedida() {
    _medidasARevisar = false;
    _alterou();
  }

  bool get _temMedida =>
      [_comprimento, _largura, _espessura].any((c) => c.text.trim().isNotEmpty);

  /// Troca o material: substitui a cópia e o preço, avisando se havia
  /// preço ajustado; com a unidade nova, pede a revisão das medidas.
  Future<void> _escolherMaterial() async {
    final novo = await escolherMaterial(context, ref);
    if (novo == null || !mounted) return;
    final atual = _material;
    final precoAtual = Dinheiro.tryParse(_preco.text);
    if (atual != null &&
        precoAtual != null &&
        precoAtual != atual.precoReferenciaCopiado) {
      final trocar = await confirmarAcao(
        context,
        titulo: 'Trocar o material?',
        mensagem:
            'O preço ajustado (${precoAtual.formatado}/'
            '${atual.unidade.simbolo}) será substituído pelo preço do '
            'cadastro de "${novo.nome}".',
        acao: 'Trocar',
      );
      if (!trocar || !mounted) return;
    }
    _material = novo.gerarSnapshot();
    _preco.text = novo.precoReferencia.formatadoSemSimbolo;
    if (atual != null && atual.unidade != novo.unidade && _temMedida) {
      _medidasARevisar = true;
    }
    _alterou();
  }

  /// Monta a peça com o que está nos campos, junto com os erros por campo.
  /// A peça é `null` quando faltam dados para montá-la.
  ({PecaOrcamento? peca, Map<_CampoPeca, String> erros}) _montar() {
    final erros = <_CampoPeca, String>{};
    final material = _material;
    final preco = Dinheiro.tryParse(_preco.text);
    final comprimento = MedidaCm.tryParse(_comprimento.text);
    final largura = MedidaCm.tryParse(_largura.text);
    final espessuraTexto = _espessura.text.trim();
    final espessura = espessuraTexto.isEmpty
        ? null
        : MedidaCm.tryParse(espessuraTexto);
    final quantidade = int.tryParse(_quantidade.text.trim());

    String medidaInvalida(String texto, String nome) => texto.trim().isEmpty
        ? 'Informe $nome'
        : 'Use um número com até duas casas (ex: 7,5)';

    if (material == null) erros[_CampoPeca.material] = 'Escolha o material';
    if (material != null && preco == null) {
      erros[_CampoPeca.preco] = _preco.text.trim().isEmpty
          ? 'Informe o preço aplicado'
          : 'Use um valor com até duas casas (ex: 90,00)';
    }
    if (material != null && comprimento == null) {
      erros[_CampoPeca.comprimento] = medidaInvalida(
        _comprimento.text,
        'o comprimento',
      );
    }
    if (material != null && largura == null) {
      erros[_CampoPeca.largura] = medidaInvalida(_largura.text, 'a largura');
    }
    if (espessuraTexto.isNotEmpty && espessura == null) {
      erros[_CampoPeca.espessura] = medidaInvalida(
        espessuraTexto,
        'a espessura',
      );
    }
    if (quantidade == null) {
      erros[_CampoPeca.quantidade] = 'Informe a quantidade';
    }
    if (material == null ||
        preco == null ||
        comprimento == null ||
        largura == null ||
        quantidade == null ||
        erros.containsKey(_CampoPeca.espessura)) {
      return (peca: null, erros: erros);
    }

    final observacoes = _observacoes.text.trim();
    final peca = PecaOrcamento(
      id: _id,
      descricao: _descricao.text.trim(),
      quantidadePorProduto: quantidade,
      material: material.copyWith(precoAplicado: preco),
      comprimentoCm: comprimento,
      larguraCm: largura,
      espessuraCm: espessura,
      observacoes: observacoes.isEmpty ? null : observacoes,
    );
    for (final erro in validarPeca(peca)) {
      final campo = _campoDoCaminho[erro.caminhoCampo];
      if (campo != null) erros.putIfAbsent(campo, () => erro.mensagem);
    }
    return (peca: peca, erros: erros);
  }

  void _salvar() {
    setState(() => _tentou = true);
    final (:peca, :erros) = _montar();
    if (peca == null || erros.isNotEmpty) return;
    // Aceita: o rascunho troca a versão do formulário, que recomeça limpo.
    _rascunho.salvarPeca(peca);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (:peca, :erros) = _montar();
    final material = _material;
    final temMaterial = material != null;
    final simbolo = material?.unidade.simbolo;
    final emM3 = material?.unidade == UnidadeCobranca.m3;
    final edicao = widget.inicial != null;
    String? erro(_CampoPeca campo) => _tentou ? erros[campo] : null;

    final precoAplicado = Dinheiro.tryParse(_preco.text);
    final ajustado =
        material != null &&
        precoAplicado != null &&
        precoAplicado != material.precoReferenciaCopiado;

    // Só calcula com a peça válida (a calculadora não aceita peça em m³
    // sem espessura); a descrição não muda o custo.
    final resultado =
        peca != null && erros.keys.every((c) => c == _CampoPeca.descricao)
        ? const CalculadoraOrcamento().calcularPeca(peca)
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            edicao ? 'Editar peça' : 'Nova peça',
            style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          CampoTexto(
            chave: 'peca-descricao',
            controller: _descricao,
            rotulo: 'Descrição da peça',
            dica: 'Ex: Tampo, Perna',
            erro: erro(_CampoPeca.descricao),
            onChanged: (_) => _alterou(),
          ),
          InkWell(
            key: const ValueKey('peca-material'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: _escolherMaterial,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Material',
                errorText: erro(_CampoPeca.material),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                material?.nome ?? 'Escolher material',
                style: AppTextStyles.body.copyWith(
                  color: temMaterial ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CampoTexto(
            chave: 'peca-preco',
            controller: _preco,
            rotulo: 'Preço aplicado',
            prefixo: r'R$ ',
            sufixo: simbolo == null ? null : '/$simbolo',
            habilitado: temMaterial,
            tipo: TipoCampo.decimal,
            ajuda: material == null
                ? 'Escolha o material primeiro'
                : ajustado
                ? 'Ajustado nesta peça. Cadastro: '
                      '${material.precoReferenciaCopiado.formatado}/$simbolo'
                : 'Preço do cadastro. Pode ajustar só nesta peça.',
            erro: erro(_CampoPeca.preco),
            onChanged: (_) => _alterou(),
          ),
          if (_medidasARevisar) ...[
            AvisoInline(
              texto:
                  'A unidade do material mudou para $simbolo. Confira as '
                  'medidas antes de aceitar a peça.',
              acao: 'Medidas conferidas',
              onAcao: () => setState(() => _medidasARevisar = false),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          CampoTexto(
            chave: 'peca-comprimento',
            controller: _comprimento,
            rotulo: 'Comprimento (cm)',
            habilitado: temMaterial,
            tipo: TipoCampo.decimal,
            erro: erro(_CampoPeca.comprimento),
            onChanged: (_) => _alterouMedida(),
          ),
          CampoTexto(
            chave: 'peca-largura',
            controller: _largura,
            rotulo: 'Largura (cm)',
            habilitado: temMaterial,
            tipo: TipoCampo.decimal,
            erro: erro(_CampoPeca.largura),
            onChanged: (_) => _alterouMedida(),
          ),
          CampoTexto(
            chave: 'peca-espessura',
            controller: _espessura,
            rotulo: emM3 ? 'Espessura (cm)' : 'Espessura (cm), opcional',
            habilitado: temMaterial,
            tipo: TipoCampo.decimal,
            ajuda: !temMaterial
                ? null
                : emM3
                ? 'Obrigatória: o material é cobrado por m³.'
                : 'Informativa: não entra no cálculo em m².',
            erro: erro(_CampoPeca.espessura),
            onChanged: (_) => _alterouMedida(),
          ),
          CampoTexto(
            chave: 'peca-quantidade',
            controller: _quantidade,
            rotulo: 'Quantidade por produto',
            ajuda: 'Quantas peças iguais vão em um produto.',
            tipo: TipoCampo.inteiro,
            erro: erro(_CampoPeca.quantidade),
            onChanged: (_) => _alterou(),
          ),
          CampoTexto(
            chave: 'peca-observacoes',
            controller: _observacoes,
            rotulo: 'Observações da peça (opcional)',
            maxLinhas: 3,
            onChanged: (_) => _alterou(),
          ),
          if (resultado != null) ...[
            LinhaResumo(
              rotulo: 'Consumo por peça',
              valor: resultado.consumoUnitario.formatadoComUnidade,
            ),
            LinhaResumo(
              rotulo: 'Custo unitário',
              valor: resultado.custoUnitario.formatado,
            ),
            if (ajustado)
              LinhaResumo(
                rotulo: 'Preço ajustado',
                valor:
                    '${precoAplicado.formatado}/$simbolo '
                    '(cadastro ${material.precoReferenciaCopiado.formatado})',
              ),
            LinhaResumo(
              rotulo: 'Custo da linha (× ${peca?.quantidadePorProduto})',
              valor: resultado.custoLinha.formatado,
              destaque: true,
            ),
          ] else
            Text(
              'Preencha material, preço e medidas para ver o custo da peça.',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (edicao)
                TextButton(
                  onPressed: _rascunho.limparFormularioPeca,
                  child: const Text('Cancelar edição'),
                ),
              OutlinedAppButton(
                label: edicao ? 'Salvar peça' : 'Adicionar peça',
                icon: edicao ? Icons.check : Icons.add,
                onPressed: _medidasARevisar ? null : _salvar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
