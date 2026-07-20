import 'package:intl/intl.dart';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

String formatMoney(double value) {
  return _moneyFormat.format(value);
}

String formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

String decimalText(double value, {int fractionDigits = 2}) {
  return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
}

String formatWeight(double value) {
  return '${decimalText(value, fractionDigits: 3)} kg/m';
}

double parseDecimal(String value) {
  return parseDecimalOrNull(value) ?? 0;
}

double? parseDecimalOrNull(String value) {
  var normalized = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (normalized.isEmpty) return null;

  final minusCount = '-'.allMatches(normalized).length;
  if (minusCount > 1 || (minusCount == 1 && !normalized.startsWith('-'))) {
    return null;
  }

  final isNegative = normalized.startsWith('-');
  normalized = normalized.replaceAll('-', '');
  if (normalized.isEmpty) return null;

  if (normalized.contains(',')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (_hasDotThousands(normalized)) {
    normalized = normalized.replaceAll('.', '');
  }

  if (isNegative) normalized = '-$normalized';
  return double.tryParse(normalized);
}

bool _hasDotThousands(String value) {
  return RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(value);
}
