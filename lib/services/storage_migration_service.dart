import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import '../models/routine_task.dart';

class StorageMigrationService {
  final BaseStorage _hiveStorage;

  StorageMigrationService(this._hiveStorage);

  static const _migrationCompletedKey = 'migration_completed';
  static const _morningKey = 'morning_tasks';
  static const _nightKey = 'night_tasks';
  static const _morningStreakCountKey = 'morning_streak_count';
  static const _nightStreakCountKey = 'night_streak_count';
  static const _morningLastStreakDateKey = 'morning_last_streak_date';
  static const _nightLastStreakDateKey = 'night_last_streak_date';
  static const _journalPrefix = 'journal_';
  static const _onboardingKey = 'onboarding_completed';

  Future<void> migrateIfNeeded() async {
    final bool isMigrated = _hiveStorage.get<bool>(_migrationCompletedKey, boxName: 'meta') ?? false;
    if (isMigrated) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 1. Migrate Onboarding
    final onboarding = prefs.getBool(_onboardingKey);
    if (onboarding != null) {
      await _hiveStorage.set(_onboardingKey, onboarding, boxName: 'meta');
    }

    // 2. Migrate Routines
    await _migrateTasks(prefs, _morningKey, 'routines');
    await _migrateTasks(prefs, _nightKey, 'routines');

    // 3. Migrate Streaks & Completions
    await _migrateStreaks(prefs);
    await _migrateCompletions(prefs);

    // 4. Migrate Journal
    await _migrateJournal(prefs);

    // 5. Mark as completed
    await _hiveStorage.set(_migrationCompletedKey, true, boxName: 'meta');
  }

  Future<void> _migrateTasks(SharedPreferences prefs, String key, String boxName) async {
    final raw = prefs.getString(key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      final tasks = list.map((e) => RoutineTask.fromJson(e as Map<String, dynamic>)).toList();
      await _hiveStorage.set(key, tasks, boxName: boxName);
    }
  }

  Future<void> _migrateStreaks(SharedPreferences prefs) async {
    final mCount = prefs.getInt(_morningStreakCountKey);
    if (mCount != null) await _hiveStorage.set(_morningStreakCountKey, mCount, boxName: 'activity');
    
    final nCount = prefs.getInt(_nightStreakCountKey);
    if (nCount != null) await _hiveStorage.set(_nightStreakCountKey, nCount, boxName: 'activity');

    final mDate = prefs.getString(_morningLastStreakDateKey);
    if (mDate != null) await _hiveStorage.set(_morningLastStreakDateKey, mDate, boxName: 'activity');

    final nDate = prefs.getString(_nightLastStreakDateKey);
    if (nDate != null) await _hiveStorage.set(_nightLastStreakDateKey, nDate, boxName: 'activity');
  }

  Future<void> _migrateCompletions(SharedPreferences prefs) async {
    for (final key in prefs.getKeys()) {
      if (key.startsWith('completion_')) {
        final raw = prefs.getString(key);
        if (raw != null) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final state = map.map((k, v) => MapEntry(k, v as bool));
          await _hiveStorage.set(key, state, boxName: 'activity');
        }
      }
    }
  }

  Future<void> _migrateJournal(SharedPreferences prefs) async {
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_journalPrefix)) {
        final date = key.substring(_journalPrefix.length);
        final raw = prefs.getString(key);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            await _hiveStorage.set(date, decoded, boxName: 'journal');
          } catch (_) {
            // Fallback for old format
            await _hiveStorage.set(date, {'text': raw, 'timestamp': ''}, boxName: 'journal');
          }
        }
      }
    }
  }
}
