import 'package:freezed_annotation/freezed_annotation.dart';

part 'erro_validacao.freezed.dart';

/// Motivo de um [ErroValidacao], estável para testes e para a interface
/// decidir como destacar o campo.
enum CodigoErroValidacao {
  /// Campo obrigatório vazio.
  obrigatorio,

  /// Valor em formato inválido (ex: CPF com dígito errado, UF minúscula).
  invalido,

  /// Valor que precisa ser maior que zero (ex: dimensão, preço aplicado).
  naoPositivo,

  /// Valor que não pode ser negativo (ex: preço base, adicionais).
  negativo,

  /// Quantidade que precisa ser pelo menos 1.
  minimoUm,

  /// Desconto maior que o subtotal.
  excedeSubtotal,

  /// Lista que precisa de pelo menos um elemento (itens, peças).
  vazio,
}

/// Um problema de validação de um campo (prompt §7, `ValidacaoService`).
///
/// [caminhoCampo] aponta o campo a partir da raiz validada, no formato
/// `itens[0].pecas[1].espessuraCm`. Não é persistido, por isso não tem JSON.
@freezed
abstract class ErroValidacao with _$ErroValidacao {
  /// Cria um [ErroValidacao].
  const factory ErroValidacao({
    /// Caminho do campo (ex: `cliente.endereco.uf`).
    required String caminhoCampo,

    /// Motivo do erro.
    required CodigoErroValidacao codigo,

    /// Mensagem pronta para exibir ao operador.
    required String mensagem,
  }) = _ErroValidacao;
}

/// Junta [prefixo] e [campo] num caminho de validação (ex: `('cliente',
/// 'nome')` → `cliente.nome`; `('', 'nome')` → `nome`).
String juntarCaminho(String prefixo, String campo) =>
    prefixo.isEmpty ? campo : '$prefixo.$campo';
