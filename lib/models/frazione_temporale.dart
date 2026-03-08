class FrazioneTemporale {
  final int id;
  final String nome;
  final bool corrente;

  FrazioneTemporale({
    required this.id,
    required this.nome,
    required this.corrente,
  });

  factory FrazioneTemporale.fromJson(Map<String, dynamic> json) {
    return FrazioneTemporale(
      id: json['id'] as int,
      nome: json['nome'] as String,
      corrente: json['corrente'] as bool? ?? false,
    );
  }
}
