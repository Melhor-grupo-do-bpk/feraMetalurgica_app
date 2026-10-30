// Código exibido do orçamento (D-30): a data de criação no formato DDMMAA e
// a sequência do dia com dois dígitos, ou mais a partir de 100. Ex:
// `281026-03` é o 3º orçamento de 28/10/2026. A sequência vem do
// `SequenciaRepository`, que nunca volta atrás.

final RegExp _codigo = RegExp(r'^(\d{2})(\d{2})(\d{2})-(\d{2,})$');

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

/// Formata o código do orçamento criado em [data] com a [sequenciaDoDia]
/// (≥ 1): `DDMMAA-NN` (ex: `281026-03`, `281026-123`).
String formatarCodigoOrcamento(DateTime data, int sequenciaDoDia) {
  if (sequenciaDoDia < 1) {
    throw ArgumentError.value(
      sequenciaDoDia,
      'sequenciaDoDia',
      'A sequência do dia começa em 1',
    );
  }
  return '${_doisDigitos(data.day)}${_doisDigitos(data.month)}'
      '${_doisDigitos(data.year % 100)}-${_doisDigitos(sequenciaDoDia)}';
}

/// Lê um código `DDMMAA-NN` de volta para a data (sem hora, ano 20AA) e a
/// sequência. Devolve `null` se o formato, a data ou a sequência forem
/// inválidos, ou se o texto não for a forma canônica (ex: `281026-003`).
({DateTime data, int sequencia})? lerCodigoOrcamento(String codigo) {
  final match = _codigo.firstMatch(codigo);
  if (match == null) return null;
  final dia = int.parse(match.group(1)!);
  final mes = int.parse(match.group(2)!);
  final ano = 2000 + int.parse(match.group(3)!);
  final sequencia = int.parse(match.group(4)!);
  final data = DateTime(ano, mes, dia);
  if (data.day != dia || data.month != mes || sequencia < 1) return null;
  if (formatarCodigoOrcamento(data, sequencia) != codigo) return null;
  return (data: data, sequencia: sequencia);
}
