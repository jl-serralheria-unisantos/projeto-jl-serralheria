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
  var normalized = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');

  if (normalized.contains(',')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  }

  return double.tryParse(normalized) ?? 0;
}
