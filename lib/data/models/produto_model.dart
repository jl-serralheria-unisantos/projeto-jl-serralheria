class Produto {
  final int? id;
  final String nome;
  final String? codigo;
  final String categoria;
  final String unidade;
  final double valorBase;
  final String? observacoes;
  final bool ativo;

  Produto({
    this.id,
    required this.nome,
    this.codigo,
    required this.categoria,
    required this.unidade,
    required this.valorBase,
    this.observacoes,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'codigo': codigo,
      'categoria': categoria,
      'unidade': unidade,
      'valor_base': valorBase,
      'observacoes': observacoes,
      'ativo': ativo ? 1 : 0,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      codigo: map['codigo'] as String?,
      categoria: map['categoria'] as String,
      unidade: map['unidade'] as String,
      valorBase: (map['valor_base'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
      ativo: map['ativo'] == 1,
    );
  }
}