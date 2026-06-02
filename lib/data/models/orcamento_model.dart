import 'package:cloud_firestore/cloud_firestore.dart';

class Orcamento {
  final String? id;
  final String clienteId;
  final DateTime dataCriacao;
  final String status;
  final double desconto;
  final double valorTotal;
  final String observacoes;
  final int validadeDias;
  final List<ItemOrcamentoEmbutido> itens;

  Orcamento({
    this.id,
    required this.clienteId,
    required this.dataCriacao,
    this.status = 'em_aberto',
    required this.desconto,
    required this.valorTotal,
    this.observacoes = '',
    this.validadeDias = 7,
    this.itens = const [],
  });

  double get subtotal =>
      itens.fold<double>(0, (total, item) => total + item.subtotal);

  double get valorFinal {
    final total = subtotal - desconto;
    return total < 0 ? 0 : total;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cliente_id': clienteId,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'status': status,
      'desconto': desconto,
      'valor_total': valorTotal,
      'observacoes': observacoes,
      'validade_dias': validadeDias,
      'itens': itens.map((i) => i.toMap()).toList(),
    };
  }

  factory Orcamento.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    final itensRaw = map['itens'] as List<dynamic>? ?? [];
    return Orcamento(
      id: doc.id,
      clienteId: map['cliente_id'] as String,
      dataCriacao: (map['data_criacao'] as Timestamp).toDate(),
      status: map['status'] as String,
      desconto: (map['desconto'] as num).toDouble(),
      valorTotal: (map['valor_total'] as num).toDouble(),
      observacoes: map['observacoes'] as String? ?? '',
      validadeDias: map['validade_dias'] as int,
      itens: itensRaw
          .map((e) => ItemOrcamentoEmbutido.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Orcamento copyWith({
    String? clienteId,
    DateTime? dataCriacao,
    String? status,
    double? desconto,
    double? valorTotal,
    String? observacoes,
    int? validadeDias,
    List<ItemOrcamentoEmbutido>? itens,
  }) {
    return Orcamento(
      id: id,
      clienteId: clienteId ?? this.clienteId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
      desconto: desconto ?? this.desconto,
      valorTotal: valorTotal ?? this.valorTotal,
      observacoes: observacoes ?? this.observacoes,
      validadeDias: validadeDias ?? this.validadeDias,
      itens: itens ?? this.itens,
    );
  }
}

class ItemOrcamentoEmbutido {
  final String tipo;
  final String? origemId;
  final String descricao;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final String? observacoes;

  ItemOrcamentoEmbutido({
    required this.tipo,
    this.origemId,
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    this.observacoes,
  });

  double get subtotal => quantidade * valorUnitario;

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'origem_id': origemId,
      'descricao': descricao,
      'quantidade': quantidade,
      'unidade': unidade,
      'valor_unitario': valorUnitario,
      'observacoes': observacoes,
    };
  }

  factory ItemOrcamentoEmbutido.fromMap(Map<String, dynamic> map) {
    return ItemOrcamentoEmbutido(
      tipo: map['tipo'] as String,
      origemId: map['origem_id'] as String?,
      descricao: map['descricao'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      unidade: map['unidade'] as String,
      valorUnitario: (map['valor_unitario'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
    );
  }
}
