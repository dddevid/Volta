/// Modello per una nota disciplinare
class Nota {
  final int id;
  final DateTime data;
  final String tipo; // 'nota', 'richiamo', 'sospensione'
  final String descrizione;
  final String? docente;
  final String? materia;

  Nota({
    required this.id,
    required this.data,
    required this.tipo,
    required this.descrizione,
    this.docente,
    this.materia,
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'] as int,
      data: DateTime.parse(json['data'] as String).toLocal(),
      tipo: json['tipo'] as String,
      descrizione: json['descrizione'] as String,
      docente: json['docente'] as String?,
      materia: json['materia'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'tipo': tipo,
      'descrizione': descrizione,
      'docente': docente,
      'materia': materia,
    };
  }
}
