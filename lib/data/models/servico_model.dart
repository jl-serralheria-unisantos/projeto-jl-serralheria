import 'package:cloud_firestore/cloud_firestore.dart';

class Servico {
  final String? id;
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

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'unidade': unidade,
      'valor_base': valorBase,
      'observacoes': observacoes,
      'ativo': ativo,
    };
  }

  factory Servico.fromFirestore(DocumentSnapshot doc) {
    final map = _documentData(doc);
    return Servico(
      id: doc.id,
      nome: _stringValue(map['nome'], fallback: 'Serviço sem nome'),
      unidade: _stringValue(map['unidade'], fallback: 'serviço'),
      valorBase: _doubleValue(map['valor_base']),
      observacoes: _optionalString(map['observacoes']),
      ativo: _boolValue(map['ativo'], fallback: true),
    );
  }
}

Map<String, dynamic> _documentData(DocumentSnapshot doc) {
  final data = doc.data();
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return const {};
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

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'sim') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'nao' ||
        normalized == 'não') {
      return false;
    }
  }
  return fallback;
}
