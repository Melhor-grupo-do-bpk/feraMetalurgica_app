import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart'
    show UnidadeCobrancaUi;
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_item.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_peca.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/aviso_total_zero.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/linha_valor.dart';
import 'package:flutter/material.dart';

/// Prévia comercial do orçamento (prompt §4, D-39): emitente, cliente,
/// produtos e totais, na ordem do documento do cliente.
///
/// Alimentada só pelos dados prontos: um orçamento salvo
/// ([PreviaOrcamento.deOrcamento]) ou a sessão do wizard com o resumo já
/// calculado ([PreviaOrcamento.daEdicao]). Não chama a calculadora nem lê
/// providers, para o PDF reaproveitar depois.
///
/// O custo das peças e dos materiais é interno: só aparece com
/// [mostrarPecas]. O documento do cliente (PDF) usa `mostrarPecas: false`.
class PreviaOrcamento extends StatelessWidget {
  /// Cria a prévia com os dados já prontos. [totais] é o resultado da
  /// calculadora para os mesmos [itens] e valores.
  const PreviaOrcamento({
    required this.emitente,
    required this.cliente,
    required this.itens,
    required this.insumos,
    required this.impostos,
    required this.combustivel,
    required this.outros,
    required this.totais,
    required this.dataEmissao,
    this.outrosDescricao,
    this.codigo,
    this.dataValidade,
    this.observacoes,
    this.mostrarPecas = false,
    super.key,
  });

  /// Prévia de um orçamento salvo, com os totais gravados (sem recalcular).
  factory PreviaOrcamento.deOrcamento(
    Orcamento orcamento, {
    bool mostrarPecas = false,
    Key? key,
  }) => PreviaOrcamento(
    key: key,
    emitente: orcamento.emitente,
    cliente: orcamento.cliente,
    itens: orcamento.itens,
    insumos: orcamento.insumos,
    impostos: orcamento.impostos,
    combustivel: orcamento.combustivel,
    outros: orcamento.outros,
    outrosDescricao: orcamento.outrosDescricao,
    totais: orcamento.totais,
    codigo: orcamento.codigoExibicao,
    dataEmissao: orcamento.atualizadoEm,
    dataValidade: orcamento.dataValidade,
    observacoes: orcamento.observacoes,
    mostrarPecas: mostrarPecas,
  );

  /// Prévia da sessão do wizard, com o [resumo] do controller e a data
  /// [agora] (a emissão, de onde conta a validade). Num orçamento novo, o
  /// código só existe depois de salvar; na edição, mostra o código com a
  /// próxima revisão (D-30). A sessão precisa ter cliente.
  factory PreviaOrcamento.daEdicao(
    OrcamentoEmEdicao edicao, {
    required ResultadoOrcamento resumo,
    required DateTime agora,
    bool mostrarPecas = false,
    Key? key,
  }) {
    final codigo = edicao.codigo;
    final dias = edicao.validadeDias;
    return PreviaOrcamento(
      key: key,
      emitente: edicao.emitente,
      cliente: edicao.cliente!,
      itens: edicao.itens,
      insumos: edicao.insumos,
      impostos: edicao.impostos,
      combustivel: edicao.combustivel,
      outros: edicao.outros,
      outrosDescricao: edicao.outrosDescricao,
      totais: resumo,
      codigo: codigo == null
          ? null
          : '$codigo rev. ${(edicao.revisao ?? 1) + 1}',
      dataEmissao: agora,
      dataValidade: dias == null
          ? null
          : DateTime(agora.year, agora.month, agora.day + dias),
      observacoes: edicao.observacoes,
      mostrarPecas: mostrarPecas,
    );
  }

  /// Cópia da empresa emitente.
  final EmpresaSnapshot emitente;

  /// Cópia do cliente.
  final ClienteSnapshot cliente;

  /// Produtos, na ordem exibida.
  final List<ItemOrcamento> itens;

  /// Insumos.
  final Dinheiro insumos;

  /// Impostos.
  final Dinheiro impostos;

  /// Combustível.
  final Dinheiro combustivel;

  /// Outros valores.
  final Dinheiro outros;

  /// Descrição de [outros].
  final String? outrosDescricao;

  /// Totais calculados (ou gravados) para estes dados.
  final ResultadoOrcamento totais;

  /// Código para exibir (ex: `281026-03 rev. 2`); `null` antes de salvar.
  final String? codigo;

  /// Data de emissão (da revisão atual).
  final DateTime dataEmissao;

  /// Data-limite da validade; `null` sem validade.
  final DateTime? dataValidade;

  /// Observações gerais.
  final String? observacoes;

  /// Se mostra o detalhe interno das peças (material, medidas e custos).
  final bool mostrarPecas;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final validade = dataValidade;
    final observacoes = this.observacoes?.trim() ?? '';
    final resultados = {for (final r in totais.itens) r.itemId: r};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          titulo: 'Orçamento',
          icone: Icons.description_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                codigo == null ? 'Número gerado ao finalizar' : 'Nº $codigo',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _Texto('Emissão: ${formatarData(dataEmissao)}'),
              if (validade != null)
                _Texto('Válido até ${formatarData(validade)}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Emitente',
          icone: Icons.business_outlined,
          child: _Pessoa(
            nome: emitente.nomeRazaoSocial,
            documento: emitente.documento.formatado,
            telefone: emitente.telefone,
            endereco: emitente.endereco,
            email: emitente.email,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Cliente',
          icone: Icons.person_outline,
          child: _Pessoa(
            nome: cliente.nome,
            documento: cliente.documento.formatado,
            telefone: cliente.celular,
            endereco: cliente.endereco,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Produtos',
          icone: Icons.inventory_2_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, item) in itens.indexed) ...[
                if (i > 0) Divider(height: AppSpacing.lg, color: colors.border),
                _Produto(
                  item: item,
                  resultado: resultados[item.id],
                  mostrarPecas: mostrarPecas,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Totais',
          icone: Icons.receipt_long_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinhaValor(
                rotulo: 'Total dos produtos',
                valor: totais.totalProdutos.formatado,
              ),
              // D-39: só os adicionais maiores que zero, cada um na sua
              // linha.
              for (final (rotulo, valor) in [
                ('Insumos', insumos),
                ('Impostos', impostos),
                ('Combustível', combustivel),
                (_rotuloOutros(outrosDescricao), outros),
              ])
                if (valor.ehPositivo)
                  LinhaValor(rotulo: rotulo, valor: valor.formatado),
              LinhaValor(rotulo: 'Subtotal', valor: totais.subtotal.formatado),
              if (totais.desconto.ehPositivo)
                LinhaValor(
                  rotulo: 'Desconto',
                  valor: '− ${totais.desconto.formatado}',
                ),
              Divider(height: AppSpacing.md, color: colors.border),
              LinhaValor(
                rotulo: 'Total geral',
                valor: totais.totalGeral.formatado,
                destaque: true,
              ),
              if (totais.totalGeralZero) ...[
                const SizedBox(height: AppSpacing.xs),
                const AvisoTotalZero(),
              ],
            ],
          ),
        ),
        if (observacoes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            titulo: 'Observações',
            icone: Icons.notes_outlined,
            child: _Texto(observacoes),
          ),
        ],
      ],
    );
  }
}

String _rotuloOutros(String? descricao) {
  final texto = descricao?.trim() ?? '';
  return texto.isEmpty ? 'Outros' : 'Outros: $texto';
}

/// Texto secundário de uma linha.
class _Texto extends StatelessWidget {
  const _Texto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
  );
}

/// Dados de contato do emitente ou do cliente.
class _Pessoa extends StatelessWidget {
  const _Pessoa({
    required this.nome,
    required this.documento,
    required this.telefone,
    required this.endereco,
    this.email,
  });

  final String nome;
  final String documento;
  final String telefone;
  final Endereco endereco;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final email = this.email?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          style: AppTextStyles.bodyStrong.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        _Texto(documento),
        _Texto(formatarTelefone(telefone)),
        if (email.isNotEmpty) _Texto(email),
        _Texto(endereco.formatado),
      ],
    );
  }
}

/// Um produto: descrição, quantidade × preço unitário e total; com
/// [mostrarPecas], o detalhe interno das peças.
class _Produto extends StatelessWidget {
  const _Produto({
    required this.item,
    required this.resultado,
    required this.mostrarPecas,
  });

  final ItemOrcamento item;
  final ResultadoItem? resultado;
  final bool mostrarPecas;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resultado = this.resultado;
    final observacoes = item.observacoes?.trim() ?? '';
    final custos = {
      for (final r in resultado?.pecas ?? const <ResultadoPeca>[]) r.pecaId: r,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.descricao,
          style: AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary),
        ),
        if (observacoes.isNotEmpty) _Texto(observacoes),
        if (resultado != null) ...[
          LinhaValor(
            rotulo:
                '${item.quantidadeProdutos} × '
                '${resultado.precoUnitario.formatado}',
            valor: resultado.totalItem.formatado,
          ),
        ],
        if (mostrarPecas) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PEÇAS (USO INTERNO)',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                for (final peca in item.pecas)
                  _Peca(
                    peca: peca,
                    consumo: custos[peca.id]?.consumoLinha.formatadoComUnidade,
                    custoLinha: custos[peca.id]?.custoLinha,
                  ),
                if (resultado != null)
                  LinhaValor(
                    rotulo: 'Materiais por produto',
                    valor: resultado.custoMateriais.formatado,
                  ),
                LinhaValor(
                  rotulo: 'Preço base por produto',
                  valor: item.precoBase.formatado,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Uma linha de peça no detalhe interno.
class _Peca extends StatelessWidget {
  const _Peca({required this.peca, this.consumo, this.custoLinha});

  final PecaOrcamento peca;
  final String? consumo;
  final Dinheiro? custoLinha;

  @override
  Widget build(BuildContext context) {
    final material = peca.material;
    final espessura = peca.espessuraCm;
    final medidas = [
      peca.comprimentoCm.formatada,
      peca.larguraCm.formatada,
      ?espessura?.formatada,
    ].join(' × ');
    final custo = custoLinha;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinhaValor(
            rotulo: '${peca.quantidadePorProduto} × ${peca.descricao}',
            valor: custo?.formatado ?? '—',
          ),
          _Texto(
            '${material.nome} • ${material.precoAplicado.formatado}/${material.unidade.simbolo}'
            '${material.precoAjustado ? ' (ajustado)' : ''}',
          ),
          _Texto('$medidas cm${consumo == null ? '' : ' • $consumo'}'),
        ],
      ),
    );
  }
}
