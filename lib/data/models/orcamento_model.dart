import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/formatters.dart';
import 'campo_monetario.dart';
import '../../shared/calculo_orcamento.dart';

class Orcamento {
  final String? id;
  final String clienteId;
  final DateTime dataCriacao;
  final String status;
  final double desconto;
  final CampoMonetario _total;
  double get valorTotal => _total.valor;
  BigInt? get totalRegistradoCentavos =>
      CalculoOrcamento.centavosMonetarios(valorTotal);
  final String observacoes;
  final String observacoesParaCliente;
  final int validadeDias;
  final List<ItemOrcamentoEmbutido> itens;

  Orcamento({
    this.id,
    required this.clienteId,
    required this.dataCriacao,
    this.status = 'em_aberto',
    required this.desconto,
    required double valorTotal,
    this.observacoes = '',
    this.observacoesParaCliente = '',
    this.validadeDias = 7,
    this.itens = const [],
  }) : _total = CampoMonetario.novo(valorTotal);

  Orcamento._({
    this.id,
    required this.clienteId,
    required this.dataCriacao,
    this.status = 'em_aberto',
    required this.desconto,
    required CampoMonetario total,
    this.observacoes = '',
    this.observacoesParaCliente = '',
    this.validadeDias = 7,
    this.itens = const [],
  }) : _total = total;

  BigInt get subtotalCentavos =>
      CalculoOrcamento.somar(itens.map((i) => i.subtotalCentavos));
  double get subtotal =>
      itens.every((i) => i.quantidade.isFinite && i.valorUnitario.isFinite)
      ? CalculoOrcamento.reais(subtotalCentavos)
      : double.nan;
  double get valorFinal => valorTotal;

  bool mesmoTotal(double proposto) {
    final registrado = totalRegistradoCentavos;
    return registrado != null &&
        registrado == CalculoOrcamento.centavosMonetarios(proposto);
  }

  bool get requerRevisao =>
      itens.any(
        (i) =>
            !CalculoOrcamento.quantidadeValida(i.quantidade) ||
            !CalculoOrcamento.valorValido(i.valorUnitario),
      ) ||
      CalculoOrcamento.erroDesconto(subtotalCentavos, desconto) != null ||
      !mesmoTotal(CalculoOrcamento.total(subtotalCentavos, desconto));

  // O mapa numérico mantém o contrato de inserção. Em atualizações, o
  // repositório conserva a representação original dos totais equivalentes.
  Map<String, dynamic> toFirestore({bool preservarTotalOriginal = false}) {
    return {
      'cliente_id': clienteId,
      'data_criacao': Timestamp.fromDate(dataCriacao),
      'status': status,
      'desconto': desconto,
      if (preservarTotalOriginal || !valorTotal.isFinite || !_total.presente)
        ..._total.campo('valor_total')
      else
        'valor_total': valorTotal,
      'observacoes': observacoes,
      if (observacoesParaCliente.isNotEmpty)
        'observacoes_para_cliente': observacoesParaCliente,
      'validade_dias': validadeDias,
      'itens': itens.map((i) => i.toMap()).toList(),
    };
  }

  factory Orcamento.fromFirestore(DocumentSnapshot doc) {
    return Orcamento.fromMap(doc.id, _documentData(doc));
  }

  factory Orcamento.fromMap(String id, Map<String, dynamic> map) {
    final itens = _itemList(map['itens']);
    final desconto = _doubleValue(map['desconto']);
    return Orcamento._(
      id: id,
      clienteId: _stringValue(map['cliente_id']),
      dataCriacao: _dateValue(map['data_criacao']),
      status: _statusValue(map['status']),
      desconto: desconto,
      total: CampoMonetario.ler(
        map,
        'valor_total',
        seAusente: () => _calcularValorFinal(itens, desconto),
      ),
      observacoes: _stringValue(map['observacoes']),
      observacoesParaCliente: switch (map['observacoes_para_cliente']) {
        final String texto => texto,
        _ => '',
      },
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
    String? observacoesParaCliente,
    int? validadeDias,
    List<ItemOrcamentoEmbutido>? itens,
  }) {
    return Orcamento._(
      id: id,
      clienteId: clienteId ?? this.clienteId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
      desconto: desconto ?? this.desconto,
      total: valorTotal == null || (_total.presente && mesmoTotal(valorTotal))
          ? _total
          : CampoMonetario.novo(valorTotal),
      observacoes: observacoes ?? this.observacoes,
      observacoesParaCliente:
          observacoesParaCliente ?? this.observacoesParaCliente,
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
  final String? detalhesParaCliente;

  ItemOrcamentoEmbutido({
    required this.tipo,
    this.origemId,
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    this.observacoes,
    this.detalhesParaCliente,
  });

  BigInt get subtotalCentavos =>
      CalculoOrcamento.centavosLinha(quantidade, valorUnitario);
  double get subtotal => quantidade.isFinite && valorUnitario.isFinite
      ? CalculoOrcamento.reais(subtotalCentavos)
      : double.nan;

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'origem_id': origemId,
      'descricao': descricao,
      'quantidade': quantidade,
      'unidade': unidade,
      'valor_unitario': valorUnitario,
      'observacoes': observacoes,
      if (detalhesParaCliente != null)
        'detalhes_para_cliente': detalhesParaCliente,
    };
  }

  factory ItemOrcamentoEmbutido.fromMap(Map<String, dynamic> map) {
    return ItemOrcamentoEmbutido(
      tipo: _tipoItemValue(map['tipo']),
      origemId: _optionalString(map['origem_id']),
      descricao: _stringValue(map['descricao'], fallback: 'Item sem descrição'),
      quantidade: _doubleValue(map['quantidade'], fallback: double.nan),
      unidade: _stringValue(map['unidade'], fallback: 'un'),
      valorUnitario: _doubleValue(map['valor_unitario'], fallback: double.nan),
      observacoes: _optionalString(map['observacoes']),
      detalhesParaCliente: switch (map['detalhes_para_cliente']) {
        final String texto => _optionalString(texto),
        _ => null,
      },
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
    return lerDecimalPersistido(value) ?? double.nan;
  }
  return fallback;
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
  final status = _stringValue(
    value,
    fallback: 'em_aberto',
  ).trim().toLowerCase();
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

// Apenas para registros antigos sem valor_total, reproduz a regra original.
double _calcularValorFinal(List<ItemOrcamentoEmbutido> itens, double desconto) {
  if (itens.isEmpty ||
      !desconto.isFinite ||
      itens.any((i) => !i.quantidade.isFinite || !i.valorUnitario.isFinite)) {
    return double.nan;
  }
  final subtotal = itens.fold<double>(
    0,
    (total, item) => total + item.quantidade * item.valorUnitario,
  );
  final total = subtotal - desconto;
  return total < 0 ? 0 : total;
}
