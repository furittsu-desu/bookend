import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MetricsRepository {
  final SharedPreferences _prefs;
  Map<String, Map<String, dynamic>>? _metricsCache;

  MetricsRepository(this._prefs);

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
    if (_metricsCache != null) {
      _metricsCache![key] = finalMetrics;
    }
  }

  Future<void> saveRoutineMetrics(String routineType, String date,
      DateTime start, DateTime end, Map<String, int> taskDurations) async {
    final key = 'metrics_${routineType}_$date';

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
      'taskDurations': finalTaskDurations,
    };
    
    await _prefs.setString(key, jsonEncode(metricsData));
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
}
