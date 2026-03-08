class Voto {
  final int id;
  final String materia;
  final String valore;
  final String? tipologia;
  final DateTime data;
  final String? descrizione;
  final String? docente;
  final double? peso;

  Voto({
    required this.id,
    required this.materia,
    required this.valore,
    this.tipologia,
    required this.data,
    this.descrizione,
    this.docente,
    this.peso,
  });

  factory Voto.fromJson(Map<String, dynamic> json) {
    return Voto(
      id: json['id'] as int? ?? 0,
      materia: json['materia'] as String? ?? '',

      valore: json['valutazione'] as String? ?? json['valore'] as String? ?? '',
      tipologia: json['tipologia'] as String?,
      data: DateTime.parse(json['data'] as String).toLocal(),
      descrizione: json['descrizione'] as String?,
      docente: json['docente'] as String?,
      peso: json['peso'] != null ? (json['peso'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materia': materia,
      'valore': valore,
      'tipologia': tipologia,
      'data': data.toIso8601String(),
      'descrizione': descrizione,
      'docente': docente,
      'peso': peso,
    };
  }
}
