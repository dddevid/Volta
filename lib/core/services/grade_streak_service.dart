import 'package:shared_preferences/shared_preferences.dart';
import '../../models/materia_voti.dart';

class StreakUpdate {
  final int oldStreak;
  final int newStreak;
  final bool didIncrease;
  final bool didReset;

  StreakUpdate({
    required this.oldStreak,
    required this.newStreak,
    required this.didIncrease,
    required this.didReset,
  });
}

class GradeStreakService {
  static const String _streakKey = 'streak_count';
  static const String _studentIdKey = 'streak_student_id';
  static const String _gradeHistoryKey = 'grade_history_ids';

  final SharedPreferences _prefs;

  GradeStreakService(this._prefs);

  Future<void> init(int currentStudentId) async {
    final storedStudentId = _prefs.getInt(_studentIdKey);

    if (storedStudentId != null && storedStudentId != currentStudentId) {

      await _clearData();
    }

    if (storedStudentId != currentStudentId) {
      await _prefs.setInt(_studentIdKey, currentStudentId);
    }
  }

  Future<StreakUpdate?> checkAndUpdateStreak(
    int studentId,
    List<MateriaVoti> materieVoti,
  ) async {
    await init(studentId);

    final allGrades = materieVoti.expand((m) => m.voti).toList();

    allGrades.sort((a, b) => a.data.compareTo(b.data));

    final storedHistory = _getStoredGradeIds();
    final newGrades =
        allGrades.where((v) => !storedHistory.contains(v.id)).toList();

    if (newGrades.isEmpty) {
      return null;
    }

    int currentStreak = _prefs.getInt(_streakKey) ?? 0;
    int oldStreak = currentStreak;
    bool didIncrease = false;
    bool didReset = false;

    for (var vote in newGrades) {
      final value = _parseGradeValue(vote.valore);
      if (value == null) continue;

      if (value > 7.0) {
        currentStreak++;
        didIncrease = true;
      } else if (value < 6.0) {
        if (currentStreak > 0) {
          currentStreak = 0;
          didReset = true;
        }
      }

    }

    await _prefs.setInt(_streakKey, currentStreak);

    final updatedHistory =
        {...storedHistory, ...newGrades.map((v) => v.id)}.toList();
    await _saveGradeHistory(updatedHistory);

    return StreakUpdate(
      oldStreak: oldStreak,
      newStreak: currentStreak,
      didIncrease: didIncrease,
      didReset: didReset,
    );
  }

  Future<int> getStreak() async {
    return _prefs.getInt(_streakKey) ?? 0;
  }

  Set<int> _getStoredGradeIds() {
    final list = _prefs.getStringList(_gradeHistoryKey);
    if (list == null) return {};
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toSet();
  }

  Future<void> _saveGradeHistory(List<int> ids) async {
    await _prefs.setStringList(
      _gradeHistoryKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _clearData() async {
    await _prefs.remove(_streakKey);
    await _prefs.remove(_gradeHistoryKey);
    await _prefs.remove(_studentIdKey);
  }

  double? _parseGradeValue(String value) {

    String normalized = value.replaceAll(',', '.').replaceAll('½', '.5');

    double? parsed = double.tryParse(normalized);
    if (parsed != null) return parsed;

    final numericString = normalized.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericString);
  }
}
