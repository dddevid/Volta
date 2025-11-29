import 'voto.dart';

class MateriaVoti {
  final int id;
  final String materia;
  final int conteggioVoti;
  final String? media;
  final List<Voto> voti;

  MateriaVoti({
    required this.id,
    required this.materia,
    required this.conteggioVoti,
    this.media,
    required this.voti,
  });

  factory MateriaVoti.fromJson(Map<String, dynamic> json) {
    var votiList = <Voto>[];
    if (json['voti'] != null) {
      votiList = (json['voti'] as List).map((v) {
        final votoJson = v as Map<String, dynamic>;
        // Inject materia into each voto
        votoJson['materia'] = json['materia'] as String? ?? '';
        // Nuvola API doesn't provide a unique ID for each grade, so we create one.
        if (votoJson['id'] == null) {
          votoJson['id'] = (json['materia'].toString() +
                  (votoJson['data'] ?? '') +
                  (votoJson['valutazione'] ?? ''))
              .hashCode;
        }
        return Voto.fromJson(votoJson);
      }).toList();
    }

    return MateriaVoti(
      id: json['id'] as int,
      materia: json['materia'] as String,
      conteggioVoti: json['conteggioVoti'] as int,
      media: json['media'] as String?,
      voti: votiList,
    );
  }
}
