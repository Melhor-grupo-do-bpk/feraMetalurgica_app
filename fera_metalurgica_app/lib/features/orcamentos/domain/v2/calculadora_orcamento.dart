import 'package:fera_metalurgica_app/core/domain/consumo.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_item.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_peca.dart';

/// 10¹²: a escala do `Consumo`.
final BigInt _escalaConsumo = BigInt.from(10).pow(Consumo.casasDecimais);

/// Metade da escala, para o arredondamento half-up.
final BigInt _meiaEscala = _escalaConsumo ~/ BigInt.two;

/// Centésimos de cm² → m² na escala 10¹²: (c/100 cm)·(l/100 cm) =
/// c·l/10⁸ m², então ×10⁴.
final BigInt _fatorM2 = BigInt.from(10000);

/// Cálculo do orçamento por peças (prompt §5, D-26). Pura e determinística:
/// não acessa banco, cadastro, relógio nem widgets, e não usa `double`.
///
/// Fórmulas:
/// ```text
/// consumoUnitario (m²) = C × L        (m³) = C × L × E   (em metros)
/// custoUnitarioPeca     = arredondarCentavos(consumoUnitario × precoAplicado)
/// custoLinhaPeca        = custoUnitarioPeca × quantidadePorProduto
/// custoMateriaisProduto = soma dos custoLinhaPeca
/// precoUnitarioProduto  = custoMateriaisProduto + precoBase
/// totalItem             = precoUnitarioProduto × quantidadeProdutos
/// subtotal              = soma dos totalItem + insumos + impostos
///                         + combustivel + outros
/// totalGeral            = subtotal − desconto
/// ```
/// O único arredondamento (half-up) é no custo de UMA peça; depois tudo é
/// multiplicação por inteiro e soma em centavos.
class CalculadoraOrcamento {
  /// Cria a calculadora.
  const CalculadoraOrcamento();

  /// Versão destas fórmulas, gravada em `Orcamento.versaoCalculo`. Mude-a
  /// se o cálculo mudar, para distinguir totais antigos.
  static const int versaoCalculo = 1;

  /// Calcula uma linha de peça, para um produto.
  ///
  /// Lança [ArgumentError] se a peça em m³ não tiver espessura (peça não
  /// validada).
  ResultadoPeca calcularPeca(PecaOrcamento peca) {
    final unidade = peca.material.unidade;
    final comprimento = BigInt.from(peca.comprimentoCm.centesimos);
    final largura = BigInt.from(peca.larguraCm.centesimos);
    final BigInt escala;
    switch (unidade) {
      case UnidadeCobranca.m2:
        escala = comprimento * largura * _fatorM2;
      case UnidadeCobranca.m3:
        final espessura = peca.espessuraCm;
        if (espessura == null) {
          throw ArgumentError.value(peca, 'peca', 'Peça em m³ sem espessura');
        }
        // (c/100)·(l/100)·(e/100) cm³ = c·l·e/10⁶ cm³ = c·l·e/10¹² m³: já
        // está na escala.
        escala = comprimento * largura * BigInt.from(espessura.centesimos);
    }
    final consumoUnitario = Consumo(unidade: unidade, valor: escala);
    final custoUnitario = _arredondarCentavos(
      escala * BigInt.from(peca.material.precoAplicado.centavos),
    );
    return ResultadoPeca(
      pecaId: peca.id,
      consumoUnitario: consumoUnitario,
      consumoLinha: consumoUnitario * peca.quantidadePorProduto,
      custoUnitario: custoUnitario,
      custoLinha: custoUnitario * peca.quantidadePorProduto,
    );
  }

  /// Calcula um produto: materiais por unidade, preço unitário e total.
  ResultadoItem calcularItem(ItemOrcamento item) {
    final pecas = item.pecas.map(calcularPeca).toList();
    final custoMateriais = pecas.fold(
      Dinheiro.zero,
      (soma, peca) => soma + peca.custoLinha,
    );
    final precoUnitario = custoMateriais + item.precoBase;
    return ResultadoItem(
      itemId: item.id,
      pecas: pecas,
      custoMateriais: custoMateriais,
      precoUnitario: precoUnitario,
      totalItem: precoUnitario * item.quantidadeProdutos,
    );
  }

  /// Calcula os totais do orçamento a partir dos [itens] e dos adicionais.
  ///
  /// Lança [ArgumentError] se o total geral ficar negativo (desconto maior
  /// que o subtotal): a validação deve barrar isso antes.
  ResultadoOrcamento calcularOrcamento({
    required List<ItemOrcamento> itens,
    Dinheiro insumos = Dinheiro.zero,
    Dinheiro impostos = Dinheiro.zero,
    Dinheiro combustivel = Dinheiro.zero,
    Dinheiro outros = Dinheiro.zero,
    Dinheiro desconto = Dinheiro.zero,
  }) {
    final resultados = itens.map(calcularItem).toList();
    final totalProdutos = resultados.fold(
      Dinheiro.zero,
      (soma, item) => soma + item.totalItem,
    );
    final totalAdicionais = insumos + impostos + combustivel + outros;
    final subtotal = totalProdutos + totalAdicionais;
    final totalGeral = subtotal - desconto;
    if (totalGeral.ehNegativo) {
      throw ArgumentError.value(
        desconto,
        'desconto',
        'O total geral não pode ser negativo',
      );
    }
    return ResultadoOrcamento(
      itens: resultados,
      totalProdutos: totalProdutos,
      totalAdicionais: totalAdicionais,
      subtotal: subtotal,
      desconto: desconto,
      totalGeral: totalGeral,
    );
  }
}

/// Converte centavos × 10¹² para centavos, arredondando a metade para
/// longe do zero (half-up).
Dinheiro _arredondarCentavos(BigInt centavosEmEscala) {
  final absoluto = centavosEmEscala.abs();
  final arredondado = (absoluto + _meiaEscala) ~/ _escalaConsumo;
  final centavos = centavosEmEscala.isNegative ? -arredondado : arredondado;
  if (!centavos.isValidInt) {
    throw ArgumentError.value(
      centavosEmEscala,
      'centavosEmEscala',
      'Valor fora do limite',
    );
  }
  return Dinheiro(centavos.toInt());
}
