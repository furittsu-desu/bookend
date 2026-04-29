import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_task.dart';

class StorageService {
  static const _morningKey = 'morning_tasks';
  static const _nightKey = 'night_tasks';
  static const _completionPrefix = 'completion_';
  static const _morningStreakCountKey = 'morning_streak_count';
  static const _nightStreakCountKey = 'night_streak_count';
  static const _morningLastStreakDateKey = 'morning_last_streak_date';
  static const _nightLastStreakDateKey = 'night_last_streak_date';
  static const _journalPrefix = 'journal_';
  static const _firstLaunchKey = 'is_first_launch';

  late final SharedPreferences _prefs;

  // In-memory caches for performance optimization
  Map<String, Map<String, String>>? _journalCache;
  Map<String, Map<String, dynamic>>? _metricsCache;

  // Helper method to get the effective date
  // If before 4:00 AM, returns yesterday's date
  String getEffectiveDate() {
    final now = DateTime.now();
    if (now.hour < 4) {
      return now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    }
    return now.toIso8601String().substring(0, 10);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Default routines ──────────────────────────────────────────────

  static List<RoutineTask> get defaultMorningTasks => [
        RoutineTask(title: 'Drink a glass of water', emoji: '💧'),
        RoutineTask(title: 'Make the bed', emoji: '🛏️'),
        RoutineTask(title: 'Stretch / Meditate (5 min)', emoji: '🧘'),
        RoutineTask(title: "Review today's priorities", emoji: '📓'),
      ];

  static List<RoutineTask> get defaultNightTasks => [
        RoutineTask(title: 'Screen off (30 min before bed)', emoji: '📵'),
        RoutineTask(title: 'Read for 10 minutes', emoji: '📖'),
        RoutineTask(title: "Prepare tomorrow's outfit", emoji: '🌙'),
      ];

  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_firstLaunchKey, false);
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
    final today = getEffectiveDate();
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
      // Clear the last streak date so it can be re-earned today
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

    // Update cache if it exists
    if (_journalCache != null) {
      _journalCache![date] = {
        'text': text,
        'timestamp': timestamp,
      };
    }
  }

  String? loadJournalEntry(String date) {
    // Try cache first
    if (_journalCache != null && _journalCache!.containsKey(date)) {
      return _journalCache![date]!['text'];
    }

    final raw = _prefs.getString('$_journalPrefix$date');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['text'] as String;
    } catch (_) {
      return raw; // Old raw text format
    }
  }

  Future<void> deleteJournalEntry(String date) async {
    await _prefs.remove('$_journalPrefix$date');
    _journalCache?.remove(date);
  }

  Map<String, Map<String, String>> getAllJournalEntries() {
    if (_journalCache != null) return _journalCache!;

    final entries = <String, Map<String, String>>{};
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_journalPrefix)) {
        final date = key.substring(_journalPrefix.length);
        final raw = _prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            entries[date] = {
              'text': decoded['text'] as String? ?? '',
              'timestamp': decoded['timestamp'] as String? ?? '',
            };
          } catch (_) {
            entries[date] = {
              'text': raw,
              'timestamp': '',
            };
          }
        }
      }
    }
    _journalCache = entries;
    return entries;
  }

  // ── Metrics ─────────────────────────────────────────────────────────

  Future<void> removeTaskFromMetrics(String routineType, String date, String taskId) async {
    final key = 'metrics_${routineType}_$date';
    final existingRaw = _prefs.getString(key);
    if (existingRaw != null) {
      try {
        final existingMetrics = jsonDecode(existingRaw) as Map<String, dynamic>;
        final existingDurations = existingMetrics['taskDurations'] as Map<String, dynamic>;
        if (existingDurations.containsKey(taskId)) {
          existingDurations.remove(taskId);
          existingMetrics['taskDurations'] = existingDurations;
          await _prefs.setString(key, jsonEncode(existingMetrics));
          
          // Update cache
          if (_metricsCache != null) {
            _metricsCache![key] = existingMetrics;
          }
        }
      } catch (_) {}
    }
  }

  Future<void> addTaskToMetrics(String routineType, String date, String taskId, int durationSeconds) async {
    final key = 'metrics_${routineType}_$date';
    final existingRaw = _prefs.getString(key);
    Map<String, dynamic> finalMetrics;
    
    if (existingRaw != null) {
      try {
        finalMetrics = jsonDecode(existingRaw) as Map<String, dynamic>;
        final existingDurations = finalMetrics['taskDurations'] as Map<String, dynamic>;
        existingDurations[taskId] = (existingDurations[taskId] as int? ?? 0) + durationSeconds;
        finalMetrics['taskDurations'] = existingDurations;
      } catch (_) {
        return;
      }
    } else {
      finalMetrics = {
        'startTime': DateTime.now().toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'taskDurations': {taskId: durationSeconds},
      };
    }
    
    await _prefs.setString(key, jsonEncode(finalMetrics));
    // Update cache
    if (_metricsCache != null) {
      _metricsCache![key] = finalMetrics;
    }
  }

  Future<void> saveRoutineMetrics(String routineType, String date,
      DateTime start, DateTime end, Map<String, int> taskDurations) async {
    final key = 'metrics_${routineType}_$date';

    // Load existing metrics to merge
    Map<String, dynamic>? existingMetrics;
    final existingRaw = _prefs.getString(key);
    if (existingRaw != null) {
      try {
        existingMetrics = jsonDecode(existingRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    DateTime finalStart = start;
    DateTime finalEnd = end;
    Map<String, int> finalTaskDurations = Map<String, int>.from(taskDurations);

    if (existingMetrics != null) {
      try {
        final existingStart = DateTime.parse(existingMetrics['startTime'] as String);
        if (existingStart.isBefore(finalStart)) {
          finalStart = existingStart;
        }
      } catch (_) {}

      try {
        final existingEnd = DateTime.parse(existingMetrics['endTime'] as String);
        if (existingEnd.isAfter(finalEnd)) {
          finalEnd = existingEnd;
        }
      } catch (_) {}

      try {
        final existingDurations = existingMetrics['taskDurations'] as Map<String, dynamic>;
        existingDurations.forEach((k, v) {
          if (!finalTaskDurations.containsKey(k)) {
            finalTaskDurations[k] = v as int;
          } else {
            finalTaskDurations[k] = (finalTaskDurations[k] ?? 0) + (v as int);
          }
        });
      } catch (_) {}
    }

    final metricsData = {
      'startTime': finalStart.toIso8601String(),
      'endTime': finalEnd.toIso8601String(),
      'taskDurations': finalTaskDurations, // id -> actual seconds
    };
    
    await _prefs.setString(key, jsonEncode(metricsData));

    // Update cache if it exists
    if (_metricsCache != null) {
      _metricsCache![key] = metricsData;
    }
  }

  Map<String, Map<String, dynamic>> getAllRoutineMetrics() {
    if (_metricsCache != null) return _metricsCache!;

    final metrics = <String, Map<String, dynamic>>{};
    for (final key in _prefs.getKeys()) {
      if (key.startsWith('metrics_')) {
        final raw = _prefs.getString(key);
        if (raw != null) {
          try {
            metrics[key] = jsonDecode(raw) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
    }
    _metricsCache = metrics;
    return metrics;
  }

  // ── Backup & Restore ────────────────────────────────────────────────

  String exportData() {
    final Map<String, dynamic> allData = {};
    for (final key in _prefs.getKeys()) {
      allData[key] = _prefs.get(key);
    }
    return base64Encode(utf8.encode(jsonEncode(allData)));
  }

  Future<bool> importData(String base64String) async {
    try {
      final jsonString = utf8.decode(base64Decode(base64String));
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      await _prefs.clear();

      // Clear caches
      _journalCache = null;
      _metricsCache = null;

      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is String) {
          await _prefs.setString(entry.key, value);
        } else if (value is int) {
          await _prefs.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs.setBool(entry.key, value);
        } else if (value is List) {
          final list = value.map((e) => e.toString()).toList();
          await _prefs.setStringList(entry.key, list);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
