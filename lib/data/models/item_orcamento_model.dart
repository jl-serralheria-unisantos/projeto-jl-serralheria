class ItemOrcamento {
  final int? id;
  final int? orcamentoId;
  final int? produtoId;
  final int? servicoId;
  final String tipoItem;
  final String descricao;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final String? observacoes;

  ItemOrcamento({
    this.id,
    this.orcamentoId,
    this.produtoId,
    this.servicoId,
    required this.tipoItem,
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    this.observacoes,
  });

  double get subtotal => quantidade * valorUnitario;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orcamento_id': orcamentoId,
      'produto_id': produtoId,
      'servico_id': servicoId,
      'tipo_item': tipoItem,
      'descricao': descricao,
      'quantidade': quantidade,
      'unidade': unidade,
      'valor_unitario': valorUnitario,
      'observacoes': observacoes,
    };
  }

  factory ItemOrcamento.fromMap(Map<String, dynamic> map) {
    return ItemOrcamento(
      id: map['id'] as int?,
      orcamentoId: map['orcamento_id'] as int?,
      produtoId: map['produto_id'] as int?,
      servicoId: map['servico_id'] as int?,
      tipoItem: map['tipo_item'] as String,
      descricao: map['descricao'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      unidade: map['unidade'] as String,
      valorUnitario: (map['valor_unitario'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
    );
  }
}