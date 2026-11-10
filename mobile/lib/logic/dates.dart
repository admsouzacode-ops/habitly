import 'package:intl/intl.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Chave estável YYYY-MM-DD no fuso local, sem hora.
String dateKey(DateTime date) {
  final d = dateOnly(date);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

Set<DateTime> dateKeysToDates(Iterable<String> keys) =>
    keys.map(parseDateKey).map(dateOnly).toSet();

final dateHeadingFormat = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
final monthYearFormat = DateFormat('MMMM y', 'pt_BR');
final shortDateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

const weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String capitalizedDateHeading(DateTime date) {
  final raw = dateHeadingFormat.format(dateOnly(date));
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1);
}
