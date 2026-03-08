class VotoDettagliato {
  final DateTime data;
  final String docente;
  final String tipologia;
  final String valutazione;
  final String valutazioneMatematica;
  final bool faMedia;
  final String peso;
  final String? descrizione;
  final String? nomeObiettivo;
  final List<Obiettivo>? obiettivi;

  VotoDettagliato({
    required this.data,
    required this.docente,
    required this.tipologia,
    required this.valutazione,
    required this.valutazioneMatematica,
    required this.faMedia,
    required this.peso,
    this.descrizione,
    this.nomeObiettivo,
    this.obiettivi,
  });

  factory VotoDettagliato.fromJson(Map<String, dynamic> json) {
    return VotoDettagliato(
      data: DateTime.parse(json['data']).toLocal(),
      docente: json['docente'] ?? '',
      tipologia: json['tipologia'] ?? '',
      valutazione: json['valutazione'] ?? '',
      valutazioneMatematica: json['valutazioneMatematica']?.toString() ?? '',
      faMedia: json['faMedia'] ?? false,
      peso: json['peso'] ?? '100%',
      descrizione: json['descrizione'],
      nomeObiettivo: json['nomeObiettivo'],
      obiettivi: json['obiettivi'] != null
          ? (json['obiettivi'] as List)
              .map((o) => Obiettivo.fromJson(o))
              .toList()
          : null,
    );
  }
}

class Obiettivo {
  final String nome;
  final String valutazione;
  final String? descrizione;

  Obiettivo({
    required this.nome,
    required this.valutazione,
    this.descrizione,
  });

  factory Obiettivo.fromJson(Map<String, dynamic> json) {
    return Obiettivo(
      nome: json['nome'] ?? '',
      valutazione: json['valutazione'] ?? '',
      descrizione: json['descrizione'],
    );
  }
}

class MateriaDettagliata {
  final String materia;
  final int conteggioVoti;
  final String? media;
  final List<VotoDettagliato> voti;

  MateriaDettagliata({
    required this.materia,
    required this.conteggioVoti,
    this.media,
    required this.voti,
  });

  factory MateriaDettagliata.fromJson(Map<String, dynamic> json) {
    return MateriaDettagliata(
      materia: json['materia'] ?? '',
      conteggioVoti: json['conteggioVoti'] ?? 0,
      media: json['media'],
      voti: json['voti'] != null
          ? (json['voti'] as List)
              .map((v) => VotoDettagliato.fromJson(v))
              .toList()
          : [],
    );
  }
}
