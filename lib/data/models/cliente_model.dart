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
    final map = doc.data() as Map<String, dynamic>;
    return Cliente(
      id: doc.id,
      nome: map['nome'] as String,
      telefone: map['telefone'] as String,
      endereco: map['endereco'] as String?,
      observacoes: map['observacoes'] as String?,
    );
  }
}
