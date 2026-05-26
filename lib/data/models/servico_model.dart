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
    final map = doc.data() as Map<String, dynamic>;
    return Servico(
      id: doc.id,
      nome: map['nome'] as String,
      unidade: map['unidade'] as String,
      valorBase: (map['valor_base'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
      ativo: map['ativo'] as bool? ?? true,
    );
  }
}
