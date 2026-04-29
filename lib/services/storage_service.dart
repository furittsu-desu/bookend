import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
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

  // NOTE: In a production app, this key should be securely stored (e.g., using flutter_secure_storage)
  // or derived from a user password. Using a hardcoded key is still better than no encryption
  // for backup files, but has limitations if the app is reverse-engineered.
  static final _encryptionKey = encrypt.Key.fromUtf8('32CharLongPasswordForAES256Key!!');

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
    final today = DateTime.now().toIso8601String().substring(0, 10);
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
    final data = {
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _prefs.setString('$_journalPrefix$date', jsonEncode(data));
  }

  String? loadJournalEntry(String date) {
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
  }

  Map<String, Map<String, String>> getAllJournalEntries() {
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
    return entries;
  }

  // ── Metrics ─────────────────────────────────────────────────────────

  Future<void> saveRoutineMetrics(String routineType, String date,
      DateTime start, DateTime end, Map<String, int> taskDurations) async {
    final key = 'metrics_${routineType}_$date';
    final metrics = {
      'startTime': start.toIso8601String(),
      'endTime': end.toIso8601String(),
      'taskDurations': taskDurations, // id -> actual seconds
    };
    await _prefs.setString(key, jsonEncode(metrics));
  }

  Map<String, Map<String, dynamic>> getAllRoutineMetrics() {
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
    return metrics;
  }

  // ── Backup & Restore ────────────────────────────────────────────────

  String exportData() {
    final Map<String, dynamic> allData = {};
    for (final key in _prefs.getKeys()) {
      allData[key] = _prefs.get(key);
    }
    final jsonString = jsonEncode(allData);

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    // Combine IV and encrypted data: [IV (16 bytes)][Encrypted Data]
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setRange(0, iv.bytes.length, iv.bytes);
    combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  Future<bool> importData(String base64String) async {
    try {
      final combined = base64Decode(base64String);

      // Extract IV (first 16 bytes)
      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);

      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(encryptedBytes),
        iv: iv,
      );

      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      await _prefs.clear();
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
