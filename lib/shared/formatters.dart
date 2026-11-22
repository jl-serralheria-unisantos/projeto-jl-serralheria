import 'package:intl/intl.dart';

import 'calculo_orcamento.dart';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

String formatMoney(double value) {
  return value.isFinite ? _moneyFormat.format(value) : 'Valor inválido';
}

String formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

String quantidadeText(double value) => !value.isFinite
    ? 'Inválido'
    : value.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',');

// Não arredondar preços/descontos históricos ao preencher um editor.
String decimalText(double value) => CalculoOrcamento.valorValido(value)
    ? value.toStringAsFixed(2).replaceAll('.', ',')
    : quantidadeText(value);

double? parseDecimalOrNull(String value) => CalculoOrcamento.lerValor(value);

/// Convenção do leitor anterior para strings já armazenadas. Campos novos
/// continuam numéricos. Nunca aplicar esta interpretação a entradas do editor.
double? lerDecimalPersistido(String value) {
  var text = value.trim();
  if (RegExp(r'^-?\d{1,3}(?:\.\d{3})+(?:,\d+)?$').hasMatch(text)) {
    text = text.replaceAll('.', '');
  }
  if (!RegExp(r'^-?\d+(?:[.,]\d+)?(?:[eE][+-]?\d+)?$').hasMatch(text)) {
    return null;
  }
  final result = double.tryParse(text.replaceAll(',', '.'));
  return result != null && result.isFinite ? result : null;
}
