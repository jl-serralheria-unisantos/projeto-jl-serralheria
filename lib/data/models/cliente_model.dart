import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String? id;
  final String nome;
  final String telefone;
  final String? endereco;
  final String? observacoes;

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    this.endereco,
    this.observacoes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'observacoes': observacoes,
    };
  }

  factory Cliente.fromFirestore(DocumentSnapshot doc) {
    final map = _documentData(doc);
    return Cliente(
      id: doc.id,
      nome: _stringValue(map['nome'], fallback: 'Cliente sem nome'),
      telefone: _stringValue(map['telefone']),
      endereco: _optionalString(map['endereco']),
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

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? _optionalString(Object? value) {
  final text = _stringValue(value).trim();
  return text.isEmpty ? null : text;
}
