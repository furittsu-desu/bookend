import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_task.dart';
import '../services/time_service.dart';

class RoutineRepository {
  static const _morningKey = 'morning_tasks';
  static const _nightKey = 'night_tasks';
  static const _completionPrefix = 'completion_';
  static const _morningStreakCountKey = 'morning_streak_count';
  static const _nightStreakCountKey = 'night_streak_count';
  static const _morningLastStreakDateKey = 'morning_last_streak_date';
  static const _nightLastStreakDateKey = 'night_last_streak_date';
  static const _journalPrefix = 'journal_';
  static const _onboardingKey = 'onboarding_completed';

  static final List<RoutineTask> defaultMorningTasks = [
    RoutineTask(title: 'Drink Water', emoji: '💦'),
    RoutineTask(title: 'Make Bed', emoji: '🛌'),
    RoutineTask(title: 'Brush Teeth', emoji: '🪥'),
    RoutineTask(title: 'Journal', emoji: '📓'),
  ];

  static final List<RoutineTask> defaultNightTasks = [
    RoutineTask(title: 'Skin Care', emoji: '🧴'),
    RoutineTask(title: 'Read', emoji: '📖'),
    RoutineTask(title: 'Journal', emoji: '📓'),
    RoutineTask(title: 'Sleep', emoji: '🌙'),
  ];

  final SharedPreferences _prefs;
  final TimeService _timeService;

  final Map<String, Map<String, String>> _journalCache = {};
  bool _isCacheComplete = false;

  RoutineRepository(this._prefs, this._timeService);

  bool isOnboardingCompleted() => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  // ── Routine CRUD ──────────────────────────────────────────────────

  List<RoutineTask> _loadTasks(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => RoutineTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveTasks(String key, List<RoutineTask> tasks) async {
    final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(key, json);
  }

  List<RoutineTask> loadMorningTasks() => _loadTasks(_morningKey);
  List<RoutineTask> loadNightTasks() => _loadTasks(_nightKey);

  Future<void> saveMorningTasks(List<RoutineTask> tasks) =>
      _saveTasks(_morningKey, tasks);
  Future<void> saveNightTasks(List<RoutineTask> tasks) =>
      _saveTasks(_nightKey, tasks);

  // ── Daily completion state ────────────────────────────────────────

  String _dayKey(String routineType) {
    final today = _timeService.getEffectiveDateString();
    return '$_completionPrefix${routineType}_$today';
  }

  Future<void> saveCompletionState(
      String routineType, Map<String, bool> state) async {
    final json = jsonEncode(state);
    await _prefs.setString(_dayKey(routineType), json);
  }

  Map<String, bool> loadCompletionState(String routineType) {
    final raw = _prefs.getString(_dayKey(routineType));
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as bool));
  }

  // ── Streak Counter ──────────────────────────────────────────────────

  int getStreak(String routineType) {
    final key = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
    return _prefs.getInt(key) ?? 0;
  }
  
  String? getLastStreakDate(String routineType) {
    final key = routineType == 'morning' ? _morningLastStreakDateKey : _nightLastStreakDateKey;
    return _prefs.getString(key);
  }

  Future<void> incrementStreak(String routineType, String date) async {
    final countKey = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
    final dateKey = routineType == 'morning' ? _morningLastStreakDateKey : _nightLastStreakDateKey;
    
    final current = getStreak(routineType);
    await _prefs.setInt(countKey, current + 1);
    await _prefs.setString(dateKey, date);
  }

  Future<void> resetStreak(String routineType) async {
    final key = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
    await _prefs.setInt(key, 0);
  }

  Future<void> removeStreakForToday(String routineType, String today) async {
    if (getLastStreakDate(routineType) == today) {
      final countKey = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
      final dateKey = routineType == 'morning' ? _morningLastStreakDateKey : _nightLastStreakDateKey;
      
      final current = getStreak(routineType);
      if (current > 0) {
        await _prefs.setInt(countKey, current - 1);
      }
      await _prefs.setString(dateKey, '');
    }
  }

  // ── Journal ─────────────────────────────────────────────────────────

  Future<void> saveJournalEntry(String date, String text) async {
    final timestamp = DateTime.now().toIso8601String();
    final data = {
      'text': text,
      'timestamp': timestamp,
    };
    await _prefs.setString('$_journalPrefix$date', jsonEncode(data));

    _journalCache[date] = {
      'text': text,
      'timestamp': timestamp,
    };
  }

  String? loadJournalEntry(String date) {
    if (_journalCache.containsKey(date)) {
      return _journalCache[date]!['text'];
    }

    final raw = _prefs.getString('$_journalPrefix$date');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final text = decoded['text'] as String;
      _journalCache[date] = {
        'text': text,
        'timestamp': decoded['timestamp'] as String? ?? '',
      };
      return text;
    } catch (_) {
      _journalCache[date] = {
        'text': raw,
        'timestamp': '',
      };
      return raw;
    }
  }

  Future<void> deleteJournalEntry(String date) async {
    await _prefs.remove('$_journalPrefix$date');
    _journalCache.remove(date);
  }

  Map<String, Map<String, String>> getAllJournalEntries() {
    if (_isCacheComplete) return _journalCache;

    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_journalPrefix)) {
        final date = key.substring(_journalPrefix.length);
        if (!_journalCache.containsKey(date)) {
          final raw = _prefs.getString(key);
          if (raw != null && raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw) as Map<String, dynamic>;
              _journalCache[date] = {
                'text': decoded['text'] as String? ?? '',
                'timestamp': decoded['timestamp'] as String? ?? '',
              };
            } catch (_) {
              _journalCache[date] = {
                'text': raw,
                'timestamp': '',
              };
            }
          }
        }
      }
    }
    _isCacheComplete = true;
    return _journalCache;
  }
}
