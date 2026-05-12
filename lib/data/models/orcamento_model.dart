class Orcamento {
  final int? id;
  final int clienteId;
  final String dataCriacao;
  final String status;
  final double valorTotal;
  final String? observacoes;
  final int validadeDias;

  Orcamento({
    this.id,
    required this.clienteId,
    required this.dataCriacao,
    this.status = 'em_aberto',
    required this.valorTotal,
    this.observacoes,
    this.validadeDias = 7,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'data_criacao': dataCriacao,
      'status': status,
      'valor_total': valorTotal,
      'observacoes': observacoes,
      'validade_dias': validadeDias,
    };
  }

  factory Orcamento.fromMap(Map<String, dynamic> map) {
    return Orcamento(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      dataCriacao: map['data_criacao'] as String,
      status: map['status'] as String,
      valorTotal: (map['valor_total'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
      validadeDias: map['validade_dias'] as int,
    );
  }
}