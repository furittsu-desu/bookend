import '../services/storage_service.dart';

class MetricsRepository {
  final BaseStorage _storage;
  Map<String, Map<String, dynamic>>? _metricsCache;

  MetricsRepository(this._storage);

  Future<void> removeTaskFromMetrics(String routineType, String date, String taskId) async {
    final key = 'metrics_${routineType}_$date';
    final existingMetrics = _storage.get<Map>(key, boxName: 'activity');
    if (existingMetrics != null) {
      try {
        final existingDurations = Map<String, dynamic>.from(existingMetrics['taskDurations'] as Map);
        if (existingDurations.containsKey(taskId)) {
          existingDurations.remove(taskId);
          final updatedMetrics = Map<String, dynamic>.from(existingMetrics);
          updatedMetrics['taskDurations'] = existingDurations;
          await _storage.set(key, updatedMetrics, boxName: 'activity');
          
          if (_metricsCache != null) {
            _metricsCache![key] = updatedMetrics;
          }
        }
      } catch (_) {}
    }
  }

  Future<void> addTaskToMetrics(String routineType, String date, String taskId, int durationSeconds) async {
    final key = 'metrics_${routineType}_$date';
    final existingMetrics = _storage.get<Map>(key, boxName: 'activity');
    Map<String, dynamic> finalMetrics;
    
    if (existingMetrics != null) {
      try {
        finalMetrics = Map<String, dynamic>.from(existingMetrics);
        final existingDurations = Map<String, dynamic>.from(finalMetrics['taskDurations'] as Map);
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
    
    await _storage.set(key, finalMetrics, boxName: 'activity');
    if (_metricsCache != null) {
      _metricsCache![key] = finalMetrics;
    }
  }

  Future<void> saveRoutineMetrics(String routineType, String date,
      DateTime start, DateTime end, Map<String, int> taskDurations) async {
    final key = 'metrics_${routineType}_$date';

    final existingMetrics = _storage.get<Map>(key, boxName: 'activity');

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
        final existingDurations = existingMetrics['taskDurations'] as Map;
        existingDurations.forEach((k, v) {
          final kStr = k as String;
          if (!finalTaskDurations.containsKey(kStr)) {
            finalTaskDurations[kStr] = v as int;
          } else {
            finalTaskDurations[kStr] = (finalTaskDurations[kStr] ?? 0) + (v as int);
          }
        });
      } catch (_) {}
    }

    final metricsData = {
      'startTime': finalStart.toIso8601String(),
      'endTime': finalEnd.toIso8601String(),
      'taskDurations': finalTaskDurations,
    };
    
    await _storage.set(key, metricsData, boxName: 'activity');
    if (_metricsCache != null) {
      _metricsCache![key] = metricsData;
    }
  }

  Map<String, Map<String, dynamic>> getAllRoutineMetrics() {
    if (_metricsCache != null) return _metricsCache!;

    final metrics = <String, Map<String, dynamic>>{};
    final keys = _storage.getKeys(boxName: 'activity');
    for (final key in keys) {
      if (key.startsWith('metrics_')) {
        final data = _storage.get<Map>(key, boxName: 'activity');
        if (data != null) {
          metrics[key] = Map<String, dynamic>.from(data);
        }
      }
    }
    _metricsCache = metrics;
    return metrics;
  }

  /// Calculates the average start time for a routine over the last [days].
  /// Returns a [DateTime] with the current date but the average hour/minute.
  DateTime? getAverageStartTime(String routineType, {int days = 7}) {
    final allMetrics = getAllRoutineMetrics();
    final routineKeys = allMetrics.keys
        .where((k) => k.startsWith('metrics_${routineType}_'))
        .toList();

    if (routineKeys.isEmpty) return null;

    // Sort by date suffix (YYYY-MM-DD)
    routineKeys.sort();
    
    final recentKeys = routineKeys.length > days 
        ? routineKeys.sublist(routineKeys.length - days)
        : routineKeys;

    int totalMinutes = 0;
    int count = 0;

    for (final key in recentKeys) {
      final data = allMetrics[key]!;
      try {
        final start = DateTime.parse(data['startTime'] as String);
        // Normalize to minutes since midnight of THAT day
        // Note: startTime is actual DateTime, but we care about the time of day
        totalMinutes += start.hour * 60 + start.minute;
        count++;
      } catch (_) {}
    }

    if (count == 0) return null;
    final avgMinutes = totalMinutes ~/ count;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, avgMinutes ~/ 60, avgMinutes % 60);
  }

  /// Calculates a consistency score (0-100) based on completion frequency over [days].
  int getConsistencyScore(String routineType, {int days = 7}) {
    final allMetrics = getAllRoutineMetrics();
    
    final today = DateTime.now();
    int completions = 0;

    for (int i = 1; i <= days; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (allMetrics.containsKey('metrics_${routineType}_$dateStr')) {
        completions++;
      }
    }

    return (completions / days * 100).toInt();
  }
}
