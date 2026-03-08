import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../constants.dart';
import '../../models/alunno.dart';
import '../../models/voto.dart';
import '../../models/assenza.dart';
import '../../models/nota.dart';
import '../../models/compito.dart';
import '../../models/materia_voti.dart';
import '../../models/voto_dettagliato.dart';
import '../../models/frazione_temporale.dart';

class NuvolaApiService {
  final ApiClient _apiClient;

  NuvolaApiService(this._apiClient);

  Future<List<Alunno>> getAlunni() async {
    try {
      final response = await _apiClient.get(AppConstants.apiAlunni);

      if (response.statusCode == 200 && response.data != null) {

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

  Future<List<MateriaVoti>> getMaterieConVoti(int alunnoId,
      {int? frazioneId}) async {
    try {
      int resolvedFrazioneId;
      if (frazioneId != null) {
        resolvedFrazioneId = frazioneId;
      } else {
        final frazioni = await getFrazioniTemporaliTyped(alunnoId);
        if (frazioni.isEmpty) {
          return [];
        }
        resolvedFrazioneId = (frazioni.firstWhere(
          (f) => f.corrente,
          orElse: () => frazioni.last,
        )).id;
      }

      final votiMaterieResponse =
          await getVotiMaterie(alunnoId, resolvedFrazioneId);

      return votiMaterieResponse
          .map((materiaJson) => MateriaVoti.fromJson(materiaJson))
          .toList();
    } catch (e) {
      debugPrint('[NuvolaApi] getMaterieConVoti error: ${e.runtimeType}');
      return [];
    }
  }

  Future<List<Voto>> getVoti(int alunnoId, {int? limit}) async {
    try {

      final frazioniResponse = await getFrazioniTemporali(alunnoId);

      if (frazioniResponse.isEmpty) {
        return [];
      }

      final currentFrazione = frazioniResponse.last;
      final frazioneId = currentFrazione['id'] as int;

      final votiMaterieResponse = await getVotiMaterie(alunnoId, frazioneId);

      List<Voto> allVoti = [];
      for (var materia in votiMaterieResponse) {
        final materiaNome = materia['materia'] as String? ?? 'Sconosciuta';
        final votiList = materia['voti'] as List? ?? [];

        for (var votoJson in votiList) {
          if (votoJson is Map<String, dynamic>) {
            try {

              final Map<String, dynamic> fullJson = Map.from(votoJson);
              fullJson['materia'] = materiaNome;

              if (fullJson['id'] == null) {
                fullJson['id'] = (materiaNome +
                        (fullJson['data'] ?? '') +
                        (fullJson['valutazione'] ?? ''))
                    .hashCode;
              }

              allVoti.add(Voto.fromJson(fullJson));
            } catch (e) {
              debugPrint('[NuvolaApi] error parsing voto: ${e.runtimeType}');
            }
          }
        }
      }

      allVoti.sort((a, b) => b.data.compareTo(a.data));

      if (limit != null && allVoti.length > limit) {
        return allVoti.sublist(0, limit);
      }

      return allVoti;
    } catch (e) {
      debugPrint('[NuvolaApi] getVoti error: ${e.runtimeType}');
      return [];
    }
  }

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
      debugPrint('[NuvolaApi] getVotiMateriaDettagliati error: ${e.runtimeType}');
      return null;
    }
  }

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
      debugPrint('[NuvolaApi] getAssenze error: ${e.runtimeType}');
      return [];
    }
  }

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
      debugPrint('[NuvolaApi] getNote error: ${e.runtimeType}');
      return [];
    }
  }

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
      debugPrint('[NuvolaApi] getCompiti error: ${e.runtimeType}');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFrazioniTemporali(int alunnoId) async {
    try {
      final path = AppConstants.apiFrazioniTemporali
          .replaceAll('{id}', alunnoId.toString());
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
      debugPrint('[NuvolaApi] getFrazioniTemporali error: ${e.runtimeType}');
      return [];
    }
  }

  Future<List<FrazioneTemporale>> getFrazioniTemporaliTyped(
      int alunnoId) async {
    final raw = await getFrazioniTemporali(alunnoId);
    return raw.map((json) => FrazioneTemporale.fromJson(json)).toList();
  }

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
      debugPrint('[NuvolaApi] getVotiMaterie error: ${e.runtimeType}');
      return [];
    }
  }
}
