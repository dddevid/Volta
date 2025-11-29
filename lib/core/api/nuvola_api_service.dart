import 'api_client.dart';
import '../constants.dart';
import '../../models/alunno.dart';
import '../../models/voto.dart';
import '../../models/assenza.dart';
import '../../models/nota.dart';
import '../../models/compito.dart';
import '../../models/materia_voti.dart';
import '../../models/voto_dettagliato.dart';

/// Servizio per tutte le chiamate API di Nuvola
class NuvolaApiService {
  final ApiClient _apiClient;

  NuvolaApiService(this._apiClient);

  /// Ottiene la lista di studenti
  Future<List<Alunno>> getAlunni() async {
    try {
      final response = await _apiClient.get(AppConstants.apiAlunni);

      if (response.statusCode == 200 && response.data != null) {
        // Handle response structure with 'valori' field
        List<dynamic> data;
        if (response.data is List) {
          data = response.data as List;
        } else if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('valori')) {
            data = responseMap['valori'] as List;
          } else if (responseMap.containsKey('data')) {
            data = responseMap['data'] as List;
          } else {
            data = [responseMap];
          }
        } else {
          throw Exception('Formato risposta non riconosciuto');
        }

        return data
            .map((json) => Alunno.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Impossibile ottenere la lista studenti');
    } catch (e) {
      throw Exception('Errore nel caricamento degli studenti: $e');
    }
  }

  /// Ottiene il conteggio delle notifiche
  Future<int> getNotificheCount(int alunnoId) async {
    try {
      final path = AppConstants.apiNotificheCount
          .replaceAll('{id}', alunnoId.toString());
      final response = await _apiClient.get(
        path,
        queryParameters: {'contextAlunno': alunnoId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['count'] as int? ?? 0;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Ottiene i voti raggruppati per materia, comprensivi di media
  Future<List<MateriaVoti>> getMaterieConVoti(int alunnoId) async {
    try {
      // Step 1: Get frazioni temporali (periods)
      final frazioniResponse = await getFrazioniTemporali(alunnoId);

      if (frazioniResponse.isEmpty) {
        print('Nessuna frazione temporale trovata');
        return [];
      }

      // Get the latest period
      final currentFrazione = frazioniResponse.last;
      final frazioneId = currentFrazione['id'] as int;

      print('Using frazione ID: $frazioneId');

      // Step 2: Get voti for materie
      final votiMaterieResponse = await getVotiMaterie(alunnoId, frazioneId);

      // Convert to MateriaVoti objects
      return votiMaterieResponse
          .map((materiaJson) =>
              MateriaVoti.fromJson(materiaJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Errore caricamento voti per materia: $e');
      return [];
    }
  }

  /// Ottiene i voti dello studente
  Future<List<Voto>> getVoti(int alunnoId, {int? limit}) async {
    try {
      // Step 1: Get frazioni temporali (periods)
      final frazioniResponse = await getFrazioniTemporali(alunnoId);

      if (frazioniResponse.isEmpty) {
        print('Nessuna frazione temporale trovata');
        return [];
      }

      // Get the latest period
      final currentFrazione = frazioniResponse.last;
      final frazioneId = currentFrazione['id'] as int;

      print('Using frazione ID: $frazioneId');

      // Step 2: Get voti for materie
      final votiMaterieResponse = await getVotiMaterie(alunnoId, frazioneId);

      // Convert to Voto objects
      List<Voto> allVoti = [];
      for (var materia in votiMaterieResponse) {
        final materiaNome = materia['materia'] as String? ?? 'Sconosciuta';
        final votiList = materia['voti'] as List? ?? [];

        for (var votoJson in votiList) {
          if (votoJson is Map<String, dynamic>) {
            try {
              // Create Voto object, injecting the subject name
              final Map<String, dynamic> fullJson = Map.from(votoJson);
              fullJson['materia'] = materiaNome;

              // Generate a unique ID if missing (hash of data + subject + value)
              if (fullJson['id'] == null) {
                fullJson['id'] = (materiaNome +
                        (fullJson['data'] ?? '') +
                        (fullJson['valutazione'] ?? ''))
                    .hashCode;
              }

              allVoti.add(Voto.fromJson(fullJson));
            } catch (e) {
              print('Error parsing voto: $e');
            }
          }
        }
      }

      // Sort by date descending
      allVoti.sort((a, b) => b.data.compareTo(a.data));

      // Apply limit
      if (limit != null && allVoti.length > limit) {
        return allVoti.sublist(0, limit);
      }

      return allVoti;
    } catch (e) {
      print('Errore caricamento voti: $e');
      return [];
    }
  }

  /// Ottiene i voti dettagliati per una specifica materia
  Future<MateriaDettagliata?> getVotiMateriaDettagliati(
      int alunnoId, int frazioneId, int materiaId) async {
    try {
      final path =
          '/api-studente/v1/alunno/$alunnoId/frazione-temporale/$frazioneId/voti/materia/$materiaId';
      final response = await _apiClient.get(
        path,
        queryParameters: {'contextAlunno': alunnoId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('valori') && (data['valori'] as List).isNotEmpty) {
          final materiaJson =
              (data['valori'] as List).first as Map<String, dynamic>;
          return MateriaDettagliata.fromJson(materiaJson);
        }
      }

      return null;
    } catch (e) {
      print('Errore caricamento dettagli materia: $e');
      return null;
    }
  }

  /// Ottiene le assenze dello studente
  Future<List<Assenza>> getAssenze(int alunnoId, {int? limit}) async {
    try {
      final path =
          AppConstants.apiAssenze.replaceAll('{id}', alunnoId.toString());
      final response = await _apiClient.get(
        path,
        queryParameters: {
          'contextAlunno': alunnoId,
          if (limit != null) 'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle response structure with 'valori' field
        List<dynamic> data = [];
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('valori')) {
            data = responseMap['valori'] as List;
          }
        } else if (response.data is List) {
          data = response.data as List;
        }

        return data
            .map((json) => Assenza.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Errore caricamento assenze: $e');
      return [];
    }
  }

  /// Ottiene le note disciplinari dello studente
  Future<List<Nota>> getNote(int alunnoId, {int? limit}) async {
    try {
      final path = AppConstants.apiNote.replaceAll('{id}', alunnoId.toString());
      final response = await _apiClient.get(
        path,
        queryParameters: {
          'contextAlunno': alunnoId,
          if (limit != null) 'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> data = [];
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('valori')) {
            data = responseMap['valori'] as List;
          }
        } else if (response.data is List) {
          data = response.data as List;
        }

        return data
            .map((json) => Nota.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Errore nel caricamento delle note: $e');
      return [];
    }
  }

  /// Ottiene i compiti per una data specifica
  Future<List<Compito>> getCompiti(int alunnoId, DateTime date) async {
    try {
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      final path = AppConstants.apiCompiti
          .replaceAll('{id}', alunnoId.toString())
          .replaceAll('{date}', dateStr);

      final response = await _apiClient.get(
        path,
        queryParameters: {'contextAlunno': alunnoId},
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle response structure with 'valori' field
        List<dynamic> data = [];
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('valori')) {
            data = responseMap['valori'] as List;
          }
        } else if (response.data is List) {
          data = response.data as List;
        }

        return data
            .map((json) => Compito.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Errore caricamento compiti: $e');
      return [];
    }
  }

  /// Ottiene le frazioni temporali (periodi/quadrimestri)
  Future<List<Map<String, dynamic>>> getFrazioniTemporali(int alunnoId) async {
    try {
      final path = AppConstants.apiFrazioniTemporali
          .replaceAll('{id}', alunnoId.toString());
      final response = await _apiClient.get(
        path,
        queryParameters: {'contextAlunno': alunnoId},
      );

      print('[FRAZIONI] Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Handle valori structure if present
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('valori')) {
            print(
                '[FRAZIONI] Found ${(data['valori'] as List).length} periods');
            return List<Map<String, dynamic>>.from(data['valori'] as List);
          }
        }
        if (response.data is List) {
          print(
              '[FRAZIONI] Found ${(response.data as List).length} periods (direct list)');
          return List<Map<String, dynamic>>.from(response.data as List);
        }
      }

      print('[FRAZIONI] No periods found');
      return [];
    } catch (e) {
      print('Errore caricamento periodi: $e');
      return [];
    }
  }

  /// Ottiene i voti per materia di un periodo specifico
  Future<List<Map<String, dynamic>>> getVotiMaterie(
      int alunnoId, int frazioneId) async {
    try {
      final path = AppConstants.apiVotiMaterie
          .replaceAll('{id}', alunnoId.toString())
          .replaceAll('{frazioneId}', frazioneId.toString());

      final response = await _apiClient.get(
        path,
        queryParameters: {'contextAlunno': alunnoId},
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('valori')) {
            return List<Map<String, dynamic>>.from(data['valori'] as List);
          }
        }
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data as List);
        }
      }

      return [];
    } catch (e) {
      print('Errore caricamento voti materie: $e');
      return [];
    }
  }
}
