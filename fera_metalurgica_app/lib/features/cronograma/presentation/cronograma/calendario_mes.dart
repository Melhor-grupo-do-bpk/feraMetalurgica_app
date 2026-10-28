/// Dias da grade do calendário do mês de [mes] (só ano e mês contam), em
/// semanas de domingo a sábado, como o cabeçalho "D S T Q Q S S".
///
/// A grade começa no domingo da semana do dia 1 e termina no sábado da
/// semana do último dia, então tem 4, 5 ou 6 semanas (sempre múltiplo de
/// 7 dias). Os dias de fora do mês completam a primeira e a última semana.
List<DateTime> diasDaGrade(DateTime mes) {
  final primeiro = DateTime(mes.year, mes.month);
  final ultimo = DateTime(mes.year, mes.month + 1, 0);
  // `weekday` vai de 1 (segunda) a 7 (domingo); o domingo é a coluna 0.
  final antes = primeiro.weekday % 7;
  final depois = 6 - ultimo.weekday % 7;
  final total = antes + ultimo.day + depois;
  // `DateTime(y, m, d)` em vez de somar `Duration`: não erra na troca do
  // horário de verão.
  return [
    for (var i = 0; i < total; i++)
      DateTime(primeiro.year, primeiro.month, 1 - antes + i),
  ];
}

/// Se [a] e [b] caem no mesmo dia, ignorando a hora.
bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// [data] sem a hora (meia-noite do mesmo dia).
DateTime soDia(DateTime data) => DateTime(data.year, data.month, data.day);
