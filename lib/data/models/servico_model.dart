class Servico {
  final int? id;
  final String nome;
  final String unidade;
  final double valorBase;
  final String? observacoes;
  final bool ativo;

  Servico({
    this.id,
    required this.nome,
    required this.unidade,
    required this.valorBase,
    this.observacoes,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'unidade': unidade,
      'valor_base': valorBase,
      'observacoes': observacoes,
      'ativo': ativo ? 1 : 0,
    };
  }

  factory Servico.fromMap(Map<String, dynamic> map) {
    return Servico(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      unidade: map['unidade'] as String,
      valorBase: (map['valor_base'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
      ativo: map['ativo'] == 1,
    );
  }
}