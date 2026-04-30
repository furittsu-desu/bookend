import '../models/routine_task.dart';
import '../services/time_service.dart';
import '../services/storage_service.dart';

class RoutineRepository {
  static const _morningKey = 'morning_tasks';
  static const _nightKey = 'night_tasks';
  static const _completionPrefix = 'completion_';
  static const _morningStreakCountKey = 'morning_streak_count';
  static const _nightStreakCountKey = 'night_streak_count';
  static const _morningLastStreakDateKey = 'morning_last_streak_date';
  static const _nightLastStreakDateKey = 'night_last_streak_date';
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

  final BaseStorage _storage;
  final TimeService timeService;

  /// In-memory cache for journal entries.
  /// Keys are dates in YYYY-MM-DD format.
  final Map<String, Map<String, String>> _journalCache = {};

  /// Flag indicating if [_journalCache] contains all entries from storage.
  bool _isCacheComplete = false;

  RoutineRepository(this._storage, this.timeService);

  bool isOnboardingCompleted() => _storage.get<bool>(_onboardingKey, boxName: 'meta') ?? false;

  Future<void> completeOnboarding() async {
    await _storage.set(_onboardingKey, true, boxName: 'meta');
  }

  // ── Routine CRUD ──────────────────────────────────────────────────

  List<RoutineTask> _loadTasks(String key) {
    final list = _storage.get<List>(key, boxName: 'routines');
    return list?.cast<RoutineTask>() ?? [];
  }

  Future<void> _saveTasks(String key, List<RoutineTask> tasks) async {
    await _storage.set(key, tasks, boxName: 'routines');
  }

  List<RoutineTask> loadMorningTasks() => _loadTasks(_morningKey);
  List<RoutineTask> loadNightTasks() => _loadTasks(_nightKey);

  Future<void> saveMorningTasks(List<RoutineTask> tasks) =>
      _saveTasks(_morningKey, tasks);
  Future<void> saveNightTasks(List<RoutineTask> tasks) =>
      _saveTasks(_nightKey, tasks);

  // ── Daily completion state ────────────────────────────────────────

  String _dayKey(String routineType) {
    final today = timeService.getEffectiveDateString();
    return '$_completionPrefix${routineType}_$today';
  }

  Future<void> saveCompletionState(
      String routineType, Map<String, bool> state) async {
    await _storage.set(_dayKey(routineType), state, boxName: 'activity');
  }

  Map<String, bool> loadCompletionState(String routineType) {
    final map = _storage.get<Map>(_dayKey(routineType), boxName: 'activity');
    return map?.cast<String, bool>() ?? {};
  }

  // ── Streak Counter ──────────────────────────────────────────────────

  int getStreak(String routineType) {
    final key = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
    return _storage.get<int>(key, boxName: 'activity') ?? 0;
  }
  
  String? getLastStreakDate(String routineType) {
    final key = routineType == 'morning' ? _morningLastStreakDateKey : _nightLastStreakDateKey;
    return _storage.get<String>(key, boxName: 'activity');
  }

  Future<void> incrementStreak(String routineType, String date) async {
    final countKey = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
    final dateKey = routineType == 'morning' ? _morningLastStreakDateKey : _nightLastStreakDateKey;
    
    final current = getStreak(routineType);
    await _storage.set(countKey, current + 1, boxName: 'activity');
    await _storage.set(dateKey, date, boxName: 'activity');
  }

  Future<void> resetStreak(String routineType) async {
    final key = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
    await _storage.set(key, 0, boxName: 'activity');
  }

  Future<void> removeStreakForToday(String routineType, String today) async {
    if (getLastStreakDate(routineType) == today) {
      final countKey = routineType == 'morning' ? _morningStreakCountKey : _nightStreakCountKey;
      final dateKey = routineType == 'morning' ? _morningLastStreakDateKey : _nightLastStreakDateKey;
      
      final current = getStreak(routineType);
      if (current > 0) {
        await _storage.set(countKey, current - 1, boxName: 'activity');
      }
      await _storage.set(dateKey, '', boxName: 'activity');
    }
  }

  // ── Journal ─────────────────────────────────────────────────────────

  /// Saves a journal entry for the given [date].
  ///
  /// The entry is stored as a JSON map containing the [text] and a current timestamp.
  /// The in-memory cache is updated immediately.
  Future<void> saveJournalEntry(String date, String text) async {
    final timestamp = DateTime.now().toIso8601String();
    final data = {
      'text': text,
      'timestamp': timestamp,
    };
    await _storage.set(date, data, boxName: 'journal');

    _journalCache[date] = {
      'text': text,
      'timestamp': timestamp,
    };
  }

  String? loadJournalEntry(String date) {
    if (_journalCache.containsKey(date)) {
      return _journalCache[date]!['text'];
    }

    final data = _storage.get<Map>(date, boxName: 'journal');
    if (data == null) return null;
    
    final text = data['text'] as String? ?? '';
    final timestamp = data['timestamp'] as String? ?? '';
    
    _journalCache[date] = {
      'text': text,
      'timestamp': timestamp,
    };
    return text;
  }

  /// Deletes the journal entry for the given [date] from both storage and cache.
  Future<void> deleteJournalEntry(String date) async {
    await _storage.remove(date, boxName: 'journal');
    _journalCache.remove(date);
  }

  /// Retrieves all journal entries, performing a full scan of storage if the cache is not complete.
  ///
  /// Subsequent calls will return the authoritative in-memory cache.
  Map<String, Map<String, String>> getAllJournalEntries() {
    if (_isCacheComplete) return _journalCache;

    final keys = _storage.getKeys(boxName: 'journal');
    for (final date in keys) {
      if (!_journalCache.containsKey(date)) {
        final data = _storage.get<Map>(date, boxName: 'journal');
        if (data != null) {
          _journalCache[date] = {
            'text': data['text'] as String? ?? '',
            'timestamp': data['timestamp'] as String? ?? '',
          };
        }
      }
    }
    _isCacheComplete = true;
    return _journalCache;
  }
}
