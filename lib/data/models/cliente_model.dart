class Cliente {
  final int? id;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'observacoes': observacoes,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      telefone: map['telefone'] as String,
      endereco: map['endereco'] as String?,
      observacoes: map['observacoes'] as String?,
    );
  }
}