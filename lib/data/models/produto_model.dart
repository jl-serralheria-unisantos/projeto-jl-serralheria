import 'package:cloud_firestore/cloud_firestore.dart';

class Produto {
  final String? id;
  final String nome;
  final String? codigo;
  final String categoria;
  final String unidade;
  final double valorBase;
  final String? observacoes;
  final bool ativo;

  Produto({
    this.id,
    required this.nome,
    this.codigo,
    required this.categoria,
    required this.unidade,
    required this.valorBase,
    this.observacoes,
    this.ativo = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'codigo': codigo,
      'categoria': categoria,
      'unidade': unidade,
      'valor_base': valorBase,
      'observacoes': observacoes,
      'ativo': ativo,
    };
  }

  factory Produto.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Produto(
      id: doc.id,
      nome: map['nome'] as String,
      codigo: map['codigo'] as String?,
      categoria: map['categoria'] as String,
      unidade: map['unidade'] as String,
      valorBase: (map['valor_base'] as num).toDouble(),
      observacoes: map['observacoes'] as String?,
      ativo: map['ativo'] as bool? ?? true,
    );
  }
}
