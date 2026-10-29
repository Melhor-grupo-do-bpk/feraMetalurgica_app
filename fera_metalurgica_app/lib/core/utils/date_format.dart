import 'package:intl/intl.dart';

// Nomes de dia/mês ficam aqui (e não no `DateFormat` com locale `pt_BR`)
// para reproduzir exatamente o Figma ("Qua, 11 Out") e não depender de
// `initializeDateFormatting`. Os formatos só numéricos usam o `DateFormat`.

const List<String> _diasCurtos = [
  'Dom',
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
];

const List<String> _meses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

final DateFormat _data = DateFormat('dd/MM/yyyy');
final DateFormat _hora = DateFormat('HH:mm');

/// Data no padrão pt-BR (ex: `17/08/2026`).
String formatarData(DateTime data) => _data.format(data);

/// Hora com dois dígitos (ex: `09:00`).
String formatarHora(DateTime data) => _hora.format(data);

/// Dia da semana e mês abreviados (ex: `Qua, 11 Out`).
String formatarDiaCurto(DateTime data) =>
    '${_diasCurtos[data.weekday % 7]}, ${data.day} '
    '${_meses[data.month - 1].substring(0, 3)}';

/// Mês por extenso e ano (ex: `Outubro 2023`).
String formatarMesAno(DateTime data) =>
    '${_meses[data.month - 1]} ${data.year}';
