import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookend/repositories/metrics_repository.dart';
import 'package:bookend/services/storage_service.dart';

class FakeStorage implements BaseStorage {
  Map<String, Map<String, dynamic>> boxes = {
    'activity': {},
  };

  @override
  Future<void> init() async {}

  @override
  T? get<T>(String key, {String? boxName}) {
    return boxes[boxName ?? 'activity']?[key] as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {String? boxName}) async {
    boxes[boxName ?? 'activity']![key] = value as Map<String, dynamic>;
  }

  @override
  Future<void> remove(String key, {String? boxName}) async {
    boxes[boxName ?? 'activity']?.remove(key);
  }

  @override
  List<String> getKeys({String? boxName}) {
    return boxes[boxName ?? 'activity']?.keys.toList() ?? [];
  }

  @override
  Future<void> close() async {}

  @override
  Future<String> exportData() async => '';

  @override
  Future<bool> importData(String json) async => true;
}

void main() {
  late MetricsRepository metricsRepository;
  late FakeStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeStorage();
    metricsRepository = MetricsRepository(fakeStorage);
  });

  group('MetricsRepository - Storage Operations', () {
    test('addTaskToMetrics should create new entry if none exists', () async {
      await metricsRepository.addTaskToMetrics('morning', '2026-04-01', 'task1', 300);

      final data = fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'];
      expect(data, isNotNull);
      expect(data['taskDurations']['task1'], 300);
    });

    test('addTaskToMetrics should update existing entry', () async {
      fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'] = {
        'startTime': '2026-04-01T07:00:00Z',
        'endTime': '2026-04-01T07:05:00Z',
        'taskDurations': {'task1': 300}
      };

      await metricsRepository.addTaskToMetrics('morning', '2026-04-01', 'task1', 100);

      final data = fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'];
      expect(data['taskDurations']['task1'], 400);
    });

    test('removeTaskFromMetrics should remove specific task', () async {
      fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'] = {
        'taskDurations': {'task1': 300, 'task2': 200}
      };

      await metricsRepository.removeTaskFromMetrics('morning', '2026-04-01', 'task1');

      final data = fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'];
      expect((data['taskDurations'] as Map).containsKey('task1'), isFalse);
    });

    test('saveRoutineMetrics should merge with existing data', () async {
      fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'] = {
        'startTime': '2026-04-01T07:00:00Z',
        'endTime': '2026-04-01T07:10:00Z',
        'taskDurations': {'task1': 600}
      };

      final newStart = DateTime.parse('2026-04-01T07:05:00Z');
      final newEnd = DateTime.parse('2026-04-01T07:15:00Z');
      final newTasks = {'task1': 100, 'task2': 200};

      await metricsRepository.saveRoutineMetrics('morning', '2026-04-01', newStart, newEnd, newTasks);

      final data = fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'];
      expect(data['startTime'], '2026-04-01T07:00:00.000Z'); // Earlier wins
      expect(data['endTime'], '2026-04-01T07:15:00.000Z'); // Later wins
      expect(data['taskDurations']['task1'], 700);
      expect(data['taskDurations']['task2'], 200);
    });
  });

  group('MetricsRepository - Habit Analysis', () {
    test('getAverageStartTime should calculate correct average', () {
      fakeStorage.boxes['activity']!['metrics_morning_2026-04-01'] = {'startTime': '2026-04-01T07:00:00Z'};
      fakeStorage.boxes['activity']!['metrics_morning_2026-04-02'] = {'startTime': '2026-04-02T07:10:00Z'};
      fakeStorage.boxes['activity']!['metrics_morning_2026-04-03'] = {'startTime': '2026-04-03T07:20:00Z'};

      // Act
      final average = metricsRepository.getAverageStartTime('morning');

      // Assert
      expect(average, isNotNull);
      expect(average!.hour, 7);
      expect(average.minute, 10);
    });

    test('getAverageStartTime should return null if no data', () {
      // Act
      final average = metricsRepository.getAverageStartTime('morning');

      // Assert
      expect(average, isNull);
    });

    test('getConsistencyScore should return 100 for perfect 7-day streak', () {
      final today = DateTime.now();
      for (int i = 1; i <= 7; i++) {
        final date = today.subtract(Duration(days: i));
        final dateStr = "metrics_morning_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        fakeStorage.boxes['activity']![dateStr] = {'completed': true};
      }

      // Act
      final score = metricsRepository.getConsistencyScore('morning');

      // Assert
      expect(score, 100);
    });

    test('getConsistencyScore should return 0 if no completions in 7 days', () {
      // Act
      final score = metricsRepository.getConsistencyScore('morning');

      // Assert
      expect(score, 0);
    });
  });
}
