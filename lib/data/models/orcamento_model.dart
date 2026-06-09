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
    final map = _documentData(doc);
    final itens = _itemList(map['itens']);
    final desconto = _nonNegativeDouble(map['desconto']);
    return Orcamento(
      id: doc.id,
      clienteId: _stringValue(map['cliente_id']),
      dataCriacao: _dateValue(map['data_criacao']),
      status: _statusValue(map['status']),
      desconto: desconto,
      valorTotal: _nonNegativeDouble(
        map['valor_total'],
        fallback: _calcularValorFinal(itens, desconto),
      ),
      observacoes: _stringValue(map['observacoes']),
      validadeDias: _positiveInt(map['validade_dias'], fallback: 7),
      itens: itens,
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
      tipo: _tipoItemValue(map['tipo']),
      origemId: _optionalString(map['origem_id']),
      descricao: _stringValue(map['descricao'], fallback: 'Item sem descrição'),
      quantidade: _nonNegativeDouble(map['quantidade']),
      unidade: _stringValue(map['unidade'], fallback: 'un'),
      valorUnitario: _nonNegativeDouble(map['valor_unitario']),
      observacoes: _optionalString(map['observacoes']),
    );
  }
}

Map<String, dynamic> _documentData(DocumentSnapshot doc) {
  final data = doc.data();
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return const {};
}

Map<String, dynamic>? _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? _optionalString(Object? value) {
  final text = _stringValue(value).trim();
  return text.isEmpty ? null : text;
}

DateTime _dateValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

double _nonNegativeDouble(Object? value, {double fallback = 0}) {
  final result = _doubleValue(value, fallback: fallback);
  return result < 0 ? fallback : result;
}

int _positiveInt(Object? value, {required int fallback}) {
  int? parsed;
  if (value is num) parsed = value.toInt();
  if (value is String) parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) return fallback;
  return parsed;
}

String _statusValue(Object? value) {
  const validStatuses = {'em_aberto', 'enviado', 'aprovado', 'recusado'};
  final status = _stringValue(value, fallback: 'em_aberto')
      .trim()
      .toLowerCase();
  return validStatuses.contains(status) ? status : 'em_aberto';
}

String _tipoItemValue(Object? value) {
  const validTypes = {'produto', 'servico', 'manual'};
  final type = _stringValue(value, fallback: 'manual').trim().toLowerCase();
  return validTypes.contains(type) ? type : 'manual';
}

List<ItemOrcamentoEmbutido> _itemList(Object? value) {
  if (value is! Iterable) return const [];

  final itens = <ItemOrcamentoEmbutido>[];
  for (final rawItem in value) {
    final map = _mapValue(rawItem);
    if (map != null) itens.add(ItemOrcamentoEmbutido.fromMap(map));
  }
  return itens;
}

double _calcularValorFinal(
  List<ItemOrcamentoEmbutido> itens,
  double desconto,
) {
  final subtotal = itens.fold<double>(0, (total, item) => total + item.subtotal);
  final total = subtotal - desconto;
  return total < 0 ? 0 : total;
}
