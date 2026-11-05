const String _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const String _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

/// [texto] em minúsculas e sem acentos, para buscar e ordenar nomes sem
/// diferenciar maiúsculas nem acentos (ex: "Ácme" → "acme").
String normalizarParaBusca(String texto) {
  final buffer = StringBuffer();
  for (final char in texto.toLowerCase().split('')) {
    final i = _comAcento.indexOf(char);
    buffer.write(i < 0 ? char : _semAcento[i]);
  }
  return buffer.toString();
}

/// Compara [a] e [b] pela forma de [normalizarParaBusca], para ordenar por
/// nome em ordem alfabética.
int compararNomes(String a, String b) =>
    normalizarParaBusca(a).compareTo(normalizarParaBusca(b));
