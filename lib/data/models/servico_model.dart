import 'package:cloud_firestore/cloud_firestore.dart';

import 'campo_monetario.dart';

class Servico {
  final String? id;
  final String nome;
  final String unidade;
  final CampoMonetario _preco;
  double get valorBase => _preco.valor;
  final String? observacoes;
  final bool ativo;

  Servico({
    this.id,
    required this.nome,
    required this.unidade,
    required double valorBase,
    this.observacoes,
    this.ativo = true,
  }) : _preco = CampoMonetario.novo(valorBase);

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'unidade': unidade,
      ..._preco.campo('valor_base'),
      'observacoes': observacoes,
      'ativo': ativo,
    };
  }

  factory Servico.fromFirestore(DocumentSnapshot doc) =>
      Servico.fromMap(doc.id, _documentData(doc));

  Servico.fromMap(String documentId, Map<String, dynamic> map)
    : id = documentId,
      nome = _stringValue(map['nome'], fallback: 'Serviço sem nome'),
      unidade = _stringValue(map['unidade'], fallback: 'serviço'),
      _preco = CampoMonetario.ler(map, 'valor_base'),
      observacoes = _optionalString(map['observacoes']),
      ativo = _boolValue(map['ativo'], fallback: true);
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
