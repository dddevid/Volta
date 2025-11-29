/// Modello per un compito
class Compito {
  final int id;
  final String materia;
  final DateTime dataAssegnazione;
  final DateTime dataConsegna;
  final String descrizione;
  final String? docente;
  final List<String>? allegati;
  bool completato; // Solo locale, non sincronizzato

  Compito({
    required this.id,
    required this.materia,
    required this.dataAssegnazione,
    required this.dataConsegna,
    required this.descrizione,
    this.docente,
    this.allegati,
    this.completato = false,
  });

  factory Compito.fromJson(Map<String, dynamic> json) {
    // Handle description which comes as a List of strings in Nuvola API
    String desc = '';
    if (json['descrizioneCompito'] != null) {
      if (json['descrizioneCompito'] is List) {
        desc = (json['descrizioneCompito'] as List).join('\n');
      } else if (json['descrizioneCompito'] is String) {
        desc = json['descrizioneCompito'] as String;
      }
    } else if (json['descrizione'] != null) {
      desc = json['descrizione'] as String;
    }

    // Generate ID if missing (hash of content) since Nuvola API doesn't provide ID for homework
    int id = json['id'] as int? ??
        (json['materia'].toString() +
                json['dataAssegnazione'].toString() +
                desc)
            .hashCode;

    return Compito(
      id: id,
      materia: json['materia'] as String? ?? 'Materia sconosciuta',
      dataAssegnazione:
          DateTime.parse(json['dataAssegnazione'] as String).toLocal(),
      dataConsegna: DateTime.parse(json['dataConsegna'] as String).toLocal(),
      descrizione: desc,
      docente: json['docente'] as String?,
      allegati: json['allegati'] != null
          ? List<String>.from(json['allegati'] as List)
          : null,
      completato: json['completato'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materia': materia,
      'dataAssegnazione': dataAssegnazione.toIso8601String(),
      'dataConsegna': dataConsegna.toIso8601String(),
      'descrizione': descrizione,
      'docente': docente,
      'allegati': allegati,
      'completato': completato,
    };
  }
}
