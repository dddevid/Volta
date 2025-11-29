/// Modello per rappresentare uno studente
class Alunno {
  final int id;
  final String nome;
  final String cognome;
  final String? codiceFiscale;
  final String? classe;
  final String? sezione;
  final int? annoScolastico;

  Alunno({
    required this.id,
    required this.nome,
    required this.cognome,
    this.codiceFiscale,
    this.classe,
    this.sezione,
    this.annoScolastico,
  });

  String get nomeCompleto => '$nome $cognome';

  factory Alunno.fromJson(Map<String, dynamic> json) {
    // Handle id field - could be int or string, and might be null
    int parsedId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        parsedId = json['id'] as int;
      } else if (json['id'] is String) {
        parsedId = int.tryParse(json['id'] as String) ?? 0;
      }
    }

    return Alunno(
      id: parsedId,
      nome: json['nome'] as String? ?? '',
      cognome: json['cognome'] as String? ?? '',
      codiceFiscale: json['codiceFiscale'] as String?,
      classe: json['classe'] as String?,
      sezione: json['sezione'] as String?,
      annoScolastico: json['annoScolastico'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'codiceFiscale': codiceFiscale,
      'classe': classe,
      'sezione': sezione,
      'annoScolastico': annoScolastico,
    };
  }
}
