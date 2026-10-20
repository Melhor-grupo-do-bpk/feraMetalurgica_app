// Validadores de formulário. As funções `validarX` seguem a assinatura de
// `TextFormField.validator`: devolvem a mensagem de erro, ou `null` se o
// valor é válido.

final RegExp _naoDigito = RegExp(r'\D');
final RegExp _digitosRepetidos = RegExp(r'^(\d)\1*$');
final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Remove tudo que não é dígito (ex: `"(11) 9999-0000"` → `"1199990000"`).
String somenteDigitos(String valor) => valor.replaceAll(_naoDigito, '');

/// Se [valor] é um CPF válido (11 dígitos e dígitos verificadores
/// corretos), com ou sem máscara.
bool cpfValido(String valor) {
  final digitos = somenteDigitos(valor);
  if (digitos.length != 11 || _digitosRepetidos.hasMatch(digitos)) {
    return false;
  }
  final numeros = digitos.split('').map(int.parse).toList();

  int digitoVerificador(int tamanho) {
    var soma = 0;
    for (var i = 0; i < tamanho; i++) {
      soma += numeros[i] * (tamanho + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return digitoVerificador(9) == numeros[9] &&
      digitoVerificador(10) == numeros[10];
}

/// Se [valor] é um CNPJ válido (14 dígitos e dígitos verificadores
/// corretos), com ou sem máscara.
bool cnpjValido(String valor) {
  final digitos = somenteDigitos(valor);
  if (digitos.length != 14 || _digitosRepetidos.hasMatch(digitos)) {
    return false;
  }
  final numeros = digitos.split('').map(int.parse).toList();

  int digitoVerificador(List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < pesos.length; i++) {
      soma += numeros[i] * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  return digitoVerificador(pesos1) == numeros[12] &&
      digitoVerificador(pesos2) == numeros[13];
}

/// Campo obrigatório: rejeita vazio ou só espaços.
String? validarObrigatorio(String? valor) =>
    (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório' : null;

/// CPF ou CNPJ obrigatório e válido.
String? validarCpfCnpj(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
  return switch (somenteDigitos(valor).length) {
    11 => cpfValido(valor) ? null : 'CPF inválido',
    14 => cnpjValido(valor) ? null : 'CNPJ inválido',
    _ => 'Informe um CPF (11 dígitos) ou CNPJ (14 dígitos)',
  };
}

/// Telefone obrigatório com DDD: 10 ou 11 dígitos.
String? validarTelefone(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
  final tamanho = somenteDigitos(valor).length;
  return tamanho == 10 || tamanho == 11 ? null : 'Telefone inválido';
}

/// E-mail opcional: vazio é aceito; preenchido precisa ter formato válido.
String? validarEmail(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;
  return _email.hasMatch(valor.trim()) ? null : 'E-mail inválido';
}
