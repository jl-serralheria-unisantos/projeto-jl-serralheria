/// Entradas em reais e unidades usam a representação decimal dos campos
/// Firestore. O produto é calculado em inteiros e arredondado uma vez por linha.
class CalculoOrcamento {
  static const limiteMonetario = 999999999.99;

  static const mensagemValor =
      'Use até 9 dígitos inteiros e 2 decimais, com vírgula.';
  static const mensagemQuantidade =
      'Use quantidade positiva, até 9 inteiros e 6 decimais, com vírgula.';

  static final _agrupado = RegExp(r'^\d{1,3}(?:\.\d{3}){1,2},\d{1,6}$');
  static final _dinheiro = RegExp(r'^\d{1,9}(?:,\d{1,2})?$');
  static final _quantidade = RegExp(r'^\d{1,9}(?:,\d{1,6})?$');

  static double? lerValor(String texto) => _ler(texto, _dinheiro);
  static double? lerQuantidade(String texto) {
    final valor = _ler(texto, _quantidade);
    return valor != null && valor > 0 ? valor : null;
  }

  static double? _ler(String texto, RegExp formato) {
    var entrada = texto.trim();
    if (entrada.contains('.') && _agrupado.hasMatch(entrada)) {
      entrada = entrada.replaceAll('.', '');
    }
    if (!formato.hasMatch(entrada)) return null;
    return double.tryParse(entrada.replaceAll(',', '.'));
  }

  static bool valorValido(double valor) => lerValor(_texto(valor)) == valor;
  static bool quantidadeValida(double valor) =>
      lerQuantidade(_texto(valor)) == valor;
  static String _texto(double valor) => valor.toString().replaceAll('.', ',');

  static BigInt? centavosMonetarios(double valor) =>
      valor.isFinite && valor >= 0 ? centavosLinha(1, valor) : null;

  static BigInt centavosLinha(double quantidade, double preco) {
    if (!quantidade.isFinite || !preco.isFinite) {
      throw ArgumentError('Quantidade e preço devem ser finitos.');
    }
    final a = _decimal(quantidade);
    final b = _decimal(preco);
    final produto = a.coeficiente * b.coeficiente;
    final escala = a.escala + b.escala - 2;
    if (escala <= 0) return produto * BigInt.from(10).pow(-escala);
    final divisor = BigInt.from(10).pow(escala);
    final arredondado = (produto.abs() + divisor ~/ BigInt.two) ~/ divisor;
    return produto.isNegative ? -arredondado : arredondado;
  }

  // Inclui notação exponencial em números históricos lidos do Firestore.
  static ({BigInt coeficiente, int escala}) _decimal(double valor) {
    final partes = valor.toString().toLowerCase().split('e');
    final mantissa = partes.first.split('.');
    final expoente = partes.length == 2 ? int.parse(partes.last) : 0;
    return (
      coeficiente: BigInt.parse(mantissa.join()),
      escala: (mantissa.length == 2 ? mantissa.last.length : 0) - expoente,
    );
  }

  static BigInt somar(Iterable<BigInt> linhas) =>
      linhas.fold(BigInt.zero, (total, linha) => total + linha);
  static double reais(BigInt centavos) => centavos.toDouble() / 100;

  static String? erroDesconto(BigInt subtotal, double? desconto) {
    if (subtotal > centavosLinha(1, limiteMonetario)) {
      return 'O subtotal ultrapassa R\$ 999.999.999,99.';
    }
    if (desconto == null || !valorValido(desconto)) return mensagemValor;
    if (centavosLinha(1, desconto) > subtotal) {
      return 'O desconto não pode superar o subtotal.';
    }
    return null;
  }

  static double total(BigInt subtotal, double desconto) {
    final erro = erroDesconto(subtotal, desconto);
    if (erro != null) throw StateError(erro);
    return reais(subtotal - centavosLinha(1, desconto));
  }
}
