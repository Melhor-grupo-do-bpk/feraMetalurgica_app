import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/campo_texto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/linha_resumo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/menu_acoes_linha.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/peca_form.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/peca_linha.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/rascunho_produto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/wizard_dialogos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Explicação da separação entre preço base e adicionais (prompt §6,
/// "Cobrança duplicada").
const String textoCobrancaDuplicada =
    'O preço base vale para uma unidade do produto: a fabricação e o que '
    'mais você cobra por produto, sem os materiais, que vêm das peças. '
    'Insumos, impostos, combustível e outros entram na etapa 3, para o '
    'orçamento todo. Inclua cada despesa em um lugar só.';

/// Formulário do produto em montagem (prompt §4): descrição, quantidade,
/// preço base e observações, a composição de peças e o resumo do produto,
/// tudo calculado pela `CalculadoraOrcamento`.
///
/// Mostrado pela etapa 2 enquanto há um `rascunhoProdutoProvider`. Grava no
/// orçamento só em "Adicionar produto" (ou "Salvar produto", na edição).
class ProdutoForm extends ConsumerStatefulWidget {
  /// Cria o formulário. A etapa usa o id do produto como `key`.
  const ProdutoForm({super.key});

  @override
  ConsumerState<ProdutoForm> createState() => _ProdutoFormState();
}

class _ProdutoFormState extends ConsumerState<ProdutoForm> {
  late final TextEditingController _descricao;
  late final TextEditingController _quantidade;
  late final TextEditingController _precoBase;
  late final TextEditingController _observacoes;

  /// Erros da última tentativa de gravar, por campo do produto.
  Map<String, String> _erros = const {};

  @override
  void initState() {
    super.initState();
    final origem = ref.read(rascunhoProdutoProvider)!.origem;
    _descricao = TextEditingController(text: origem.descricao);
    _quantidade = TextEditingController(text: '${origem.quantidadeProdutos}');
    _precoBase = TextEditingController(
      text: origem.precoBase.formatadoSemSimbolo,
    );
    _observacoes = TextEditingController(text: origem.observacoes);
  }

  @override
  void dispose() {
    _descricao.dispose();
    _quantidade.dispose();
    _precoBase.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  RascunhoProduto get _rascunho => ref.read(rascunhoProdutoProvider.notifier);

  void _alterou() {
    _rascunho.marcarAlterado();
    setState(() {});
  }

  Future<void> _cancelar() async {
    final rascunho = ref.read(rascunhoProdutoProvider);
    if (rascunho == null) return;
    if (rascunho.alterado) {
      final descartar = await confirmarAcao(
        context,
        titulo: rascunho.ehEdicao
            ? 'Descartar as alterações do produto?'
            : 'Descartar o produto?',
        mensagem: 'O que foi preenchido neste produto será perdido.',
        acao: 'Descartar',
      );
      if (!descartar || !mounted) return;
    }
    _rascunho.descartar();
  }

  Future<void> _concluir() async {
    final rascunho = ref.read(rascunhoProdutoProvider);
    if (rascunho == null) return;
    final quantidade = int.tryParse(_quantidade.text.trim());
    final precoBase = Dinheiro.tryParse(_precoBase.text);
    final erros = <String, String>{
      if (quantidade == null) 'quantidadeProdutos': 'Informe a quantidade',
      if (precoBase == null)
        'precoBase': _precoBase.text.trim().isEmpty
            ? 'Informe o preço base (pode ser 0,00)'
            : 'Use um valor com até duas casas (ex: 150,00)',
    };
    if (quantidade == null || precoBase == null) {
      setState(() => _erros = erros);
      return;
    }
    if (rascunho.pecaPendente) {
      final seguir = await confirmarAcao(
        context,
        titulo: 'Peça não adicionada',
        mensagem:
            'A peça em preenchimento não foi adicionada ao produto e será '
            'perdida.',
        acao: 'Continuar sem ela',
      );
      if (!seguir || !mounted) return;
    }
    final observacoes = _observacoes.text.trim();
    final errosItem = _rascunho.concluir(
      descricao: _descricao.text.trim(),
      quantidadeProdutos: quantidade,
      precoBase: precoBase,
      observacoes: observacoes.isEmpty ? null : observacoes,
    );
    if (errosItem.isNotEmpty && mounted) {
      setState(() => _erros = _porCampo(errosItem));
    }
  }

  /// Erros do produto por campo. Os caminhos vêm de `validarItem` sem
  /// prefixo (`descricao`, `pecas`...) ou do controller (`itens[0].x`).
  Map<String, String> _porCampo(List<ErroValidacao> erros) => {
    for (final erro in erros.reversed)
      erro.caminhoCampo.replaceFirst(RegExp(r'^itens\[\d+\]\.'), ''):
          erro.mensagem,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rascunho = ref.watch(rascunhoProdutoProvider);
    if (rascunho == null) return const SizedBox.shrink();
    const calculadora = CalculadoraOrcamento();
    final quantidade = int.tryParse(_quantidade.text.trim());
    final precoBase = Dinheiro.tryParse(_precoBase.text);
    final resultado =
        rascunho.pecas.isNotEmpty &&
            quantidade != null &&
            quantidade >= 1 &&
            precoBase != null
        ? calculadora.calcularItem(
            rascunho.origem.copyWith(
              quantidadeProdutos: quantidade,
              precoBase: precoBase,
              pecas: rascunho.pecas,
            ),
          )
        : null;
    final erroPecas = _erros['pecas'];

    return SectionCard(
      titulo: rascunho.ehEdicao ? 'Editar produto' : 'Novo produto',
      icone: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoTexto(
            chave: 'produto-descricao',
            controller: _descricao,
            rotulo: 'Descrição do produto',
            dica: 'Ex: Mesa de jantar sob medida',
            erro: _erros['descricao'],
            onChanged: (_) => _alterou(),
          ),
          CampoTexto(
            chave: 'produto-quantidade',
            controller: _quantidade,
            rotulo: 'Quantidade de produtos',
            ajuda: 'Quantos produtos iguais serão vendidos.',
            tipo: TipoCampo.inteiro,
            erro: _erros['quantidadeProdutos'],
            onChanged: (_) => _alterou(),
          ),
          CampoTexto(
            chave: 'produto-preco-base',
            controller: _precoBase,
            rotulo: 'Preço base de fabricação por produto (sem materiais)',
            prefixo: r'R$ ',
            tipo: TipoCampo.decimal,
            erro: _erros['precoBase'],
            onChanged: (_) => _alterou(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              textoCobrancaDuplicada,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          CampoTexto(
            chave: 'produto-observacoes',
            controller: _observacoes,
            rotulo: 'Observações do produto (opcional)',
            maxLinhas: 3,
            onChanged: (_) => _alterou(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Peças de um produto',
            style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (rascunho.pecas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                erroPecas ?? 'Nenhuma peça adicionada.',
                style: AppTextStyles.body.copyWith(
                  color: erroPecas == null
                      ? colors.textSecondary
                      : colors.error,
                ),
              ),
            ),
          for (final (i, peca) in rascunho.pecas.indexed)
            PecaLinha(
              key: ValueKey('peca-linha-${peca.id}'),
              peca: peca,
              resultado: resultado?.pecas[i] ?? calculadora.calcularPeca(peca),
              emEdicao: peca.id == rascunho.pecaEmEdicaoId,
              onAcao: (acao) => _acaoPeca(acao, peca.id, peca.descricao),
            ),
          const SizedBox(height: AppSpacing.xs),
          PecaForm(
            key: ValueKey('peca-form-${rascunho.versaoFormularioPeca}'),
            inicial: rascunho.pecaEmEdicao,
          ),
          const SizedBox(height: AppSpacing.md),
          if (resultado != null) ...[
            LinhaResumo(
              rotulo: 'Materiais por produto',
              valor: resultado.custoMateriais.formatado,
            ),
            LinhaResumo(
              rotulo: 'Preço unitário (com o preço base)',
              valor: resultado.precoUnitario.formatado,
            ),
            LinhaResumo(
              rotulo: 'Total do produto (× $quantidade)',
              valor: resultado.totalItem.formatado,
              destaque: true,
            ),
          ] else
            Text(
              'Adicione uma peça e informe quantidade e preço base para '
              'ver o total do produto.',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                ),
                onPressed: _cancelar,
                child: const Text('Cancelar'),
              ),
              PrimaryButton(
                label: rascunho.ehEdicao
                    ? 'Salvar produto'
                    : 'Adicionar produto',
                icon: Icons.check,
                onPressed: _concluir,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acaoPeca(AcaoLinha acao, String pecaId, String nome) async {
    switch (acao) {
      case AcaoLinha.editar:
        _rascunho.editarPeca(pecaId);
      case AcaoLinha.duplicar:
        _rascunho.duplicarPeca(pecaId);
      case AcaoLinha.remover:
        final remover = await confirmarAcao(
          context,
          titulo: 'Remover a peça?',
          mensagem: '"$nome" sai deste produto.',
          acao: 'Remover',
        );
        if (remover && mounted) _rascunho.removerPeca(pecaId);
    }
  }
}
