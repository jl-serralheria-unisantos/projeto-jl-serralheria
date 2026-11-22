import '../../shared/formatters.dart';

/// Mantém o campo original para que uma leitura ou uma alteração de status
/// não normalize um documento antigo. Ausência e null explícito são distintos.
class CampoMonetario {
  CampoMonetario.novo(double valor) : this._(valor, valor, true);

  const CampoMonetario._(this.valor, this._bruto, this.presente);

  final double valor;
  final Object? _bruto;
  final bool presente;

  factory CampoMonetario.ler(
    Map<String, dynamic> dados,
    String chave, {
    double Function()? seAusente,
  }) {
    if (!dados.containsKey(chave)) {
      return CampoMonetario._(seAusente?.call() ?? double.nan, null, false);
    }
    final bruto = dados[chave];
    final valor = switch (bruto) {
      num n => n.toDouble(),
      String s => _lerMoeda(s),
      _ => null,
    };
    return CampoMonetario._(valor ?? double.nan, bruto, true);
  }

  Map<String, dynamic> campo(String chave) => {if (presente) chave: _bruto};

  static double? _lerMoeda(String texto) {
    final s = texto.trim();
    if (!s.startsWith(r'R$')) {
      // Com um único ponto e três casas, a escala do valor é ambígua.
      if (RegExp(r'^-?\d{1,3}\.\d{3}$').hasMatch(s)) return null;
      return lerDecimalPersistido(s);
    }
    final numero = s.substring(2).trim();
    if (!RegExp(
      r'^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$',
    ).hasMatch(numero)) {
      return null;
    }
    return lerDecimalPersistido(numero);
  }
}
