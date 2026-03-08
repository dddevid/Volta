class Assenza {
  final int id;
  final DateTime data;
  final String tipo;
  final bool giustificata;
  final String? motivazione;
  final DateTime? dataGiustificazione;

  Assenza({
    required this.id,
    required this.data,
    required this.tipo,
    required this.giustificata,
    this.motivazione,
    this.dataGiustificazione,
  });

  factory Assenza.fromJson(Map<String, dynamic> json) {
    return Assenza(
      id: json['id'] as int,
      data: DateTime.parse(json['data'] as String).toLocal(),
      tipo: (json['tipo'] as String).toLowerCase(),
      giustificata: json['giustificata'] as bool? ?? false,
      motivazione: json['motivazione'] as String?,
      dataGiustificazione: json['dataGiustificazione'] != null
          ? DateTime.parse(json['dataGiustificazione'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'tipo': tipo,
      'giustificata': giustificata,
      'motivazione': motivazione,
      'dataGiustificazione': dataGiustificazione?.toIso8601String(),
    };
  }
}
