import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookend/services/storage_service.dart';
import 'package:bookend/repositories/routine_repository.dart';
import 'package:bookend/services/time_service.dart';
import 'package:bookend/models/routine_task.dart';
import 'package:bookend/services/notification_service.dart';

class FakeStorage implements BaseStorage {
  Map<String, Map<String, dynamic>> boxes = {
    'meta': {},
    'routines': {},
    'activity': {},
    'journal': {},
  };

  @override
  Future<void> init() async {}

  @override
  T? get<T>(String key, {String? boxName}) {
    return boxes[boxName ?? 'meta']?[key] as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {String? boxName}) async {
    boxes[boxName ?? 'meta']![key] = value;
  }

  @override
  Future<void> remove(String key, {String? boxName}) async {
    boxes[boxName ?? 'meta']?.remove(key);
  }

  @override
  List<String> getKeys({String? boxName}) {
    return boxes[boxName ?? 'meta']?.keys.toList() ?? [];
  }

  @override
  Future<void> close() async {}

  @override
  Future<String> exportData() async => '';

  @override
  Future<bool> importData(String json) async => true;
}

class MockTimeService extends Mock implements TimeService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late RoutineRepository repository;
  late FakeStorage storage;
  late MockTimeService mockTimeService;
  late MockNotificationService mockNotificationService;

  setUp(() {
    storage = FakeStorage();
    mockTimeService = MockTimeService();
    mockNotificationService = MockNotificationService();
    
    // Default stubs
    when(() => mockNotificationService.cancelNudgeChain(any())).thenAnswer((_) async => {});
    when(() => mockNotificationService.scheduleNudgeChain(
      routineId: any(named: 'routineId'),
      startTime: any(named: 'startTime'),
      title: any(named: 'title'),
    )).thenAnswer((_) async => {});

    repository = RoutineRepository(storage, mockTimeService, 
        notificationService: mockNotificationService);
  });

  group('RoutineRepository', () {
    test('isOnboardingCompleted returns false if not set', () {
      expect(repository.isOnboardingCompleted(), isFalse);
    });

    test('isOnboardingCompleted returns true if set to true', () {
      storage.boxes['meta']!['onboarding_completed'] = true;
      expect(repository.isOnboardingCompleted(), isTrue);
    });

    test('completeOnboarding sets flag', () async {
      await repository.completeOnboarding();
      expect(storage.boxes['meta']!['onboarding_completed'], true);
    });

    test('loadMorningTasks returns tasks from storage', () {
      final tasks = [RoutineTask(title: 'Morning')];
      storage.boxes['routines']!['morning_tasks'] = tasks;
      
      final result = repository.loadMorningTasks();
      expect(result.first.title, 'Morning');
    });

    test('loadNightTasks returns tasks from storage', () {
      final tasks = [RoutineTask(title: 'Night')];
      storage.boxes['routines']!['night_tasks'] = tasks;
      
      final result = repository.loadNightTasks();
      expect(result.first.title, 'Night');
    });

    test('saveMorningTasks saves to storage', () async {
      final tasks = [RoutineTask(title: 'Test')];
      await repository.saveMorningTasks(tasks);
      expect(storage.boxes['routines']!['morning_tasks'], tasks);
    });

    test('saveNightTasks saves to storage', () async {
      final tasks = [RoutineTask(title: 'Test Night')];
      await repository.saveNightTasks(tasks);
      expect(storage.boxes['routines']!['night_tasks'], tasks);
    });

    group('Completion State', () {
      test('saveCompletionState saves to storage with date key', () async {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        
        final state = {'task-id': true};
        await repository.saveCompletionState('morning', state);
        
        expect(storage.boxes['activity']!['completion_morning_2026-04-30'], state);
      });

      test('loadCompletionState returns map from storage', () {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        final state = {'task-id': true};
        storage.boxes['activity']!['completion_morning_2026-04-30'] = state;
        
        final result = repository.loadCompletionState('morning');
        expect(result['task-id'], true);
      });

      test('loadCompletionState returns empty map if not set', () {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        
        final result = repository.loadCompletionState('morning');
        expect(result, isEmpty);
      });
    });

    test('getStreak returns value from storage', () {
      storage.boxes['activity']!['morning_streak_count'] = 5;
      expect(repository.getStreak('morning'), 5);
    });

    test('incrementStreak updates count and date', () async {
      storage.boxes['activity']!['morning_streak_count'] = 5;
      
      await repository.incrementStreak('morning', '2026-04-29');
      
      expect(storage.boxes['activity']!['morning_streak_count'], 6);
      expect(storage.boxes['activity']!['morning_last_streak_date'], '2026-04-29');
    });

    test('resetStreak sets count to zero', () async {
      storage.boxes['activity']!['morning_streak_count'] = 5;
      await repository.resetStreak('morning');
      expect(storage.boxes['activity']!['morning_streak_count'], 0);
    });

    group('removeStreakForToday', () {
      test('removes streak if date matches', () async {
        storage.boxes['activity']!['morning_last_streak_date'] = '2026-04-30';
        storage.boxes['activity']!['morning_streak_count'] = 5;

        await repository.removeStreakForToday('morning', '2026-04-30');

        expect(storage.boxes['activity']!['morning_streak_count'], 4);
        expect(storage.boxes['activity']!['morning_last_streak_date'], '');
      });

      test('does nothing if date does not match', () async {
        storage.boxes['activity']!['morning_last_streak_date'] = '2026-04-29';
        storage.boxes['activity']!['morning_streak_count'] = 5;
        
        await repository.removeStreakForToday('morning', '2026-04-30');

        expect(storage.boxes['activity']!['morning_streak_count'], 5);
        expect(storage.boxes['activity']!['morning_last_streak_date'], '2026-04-29');
      });
    });

    group('Journal', () {
      test('loadJournalEntry returns null when no entry exists', () {
        expect(repository.loadJournalEntry('2026-04-29'), isNull);
      });

      test('loadJournalEntry returns text from valid entry', () {
        final entry = {'text': 'Hello World', 'timestamp': '2026-04-30'};
        storage.boxes['journal']!['2026-04-29'] = entry;
        
        expect(repository.loadJournalEntry('2026-04-29'), 'Hello World');
      });

      test('loadJournalEntry hits cache on subsequent calls', () {
        final entry = {'text': 'Cached entry', 'timestamp': '2026-04-30'};
        storage.boxes['journal']!['2026-04-29'] = entry;
        
        // First call - populates cache
        repository.loadJournalEntry('2026-04-29');
        
        // Modify storage - cache should still have old value
        storage.boxes['journal']!['2026-04-29'] = {'text': 'New', 'timestamp': '...'};
        
        final result = repository.loadJournalEntry('2026-04-29');
        expect(result, 'Cached entry');
      });

      test('saveJournalEntry updates cache', () async {
        await repository.saveJournalEntry('2026-04-29', 'New Text');
        
        expect(storage.boxes['journal']!['2026-04-29']!['text'], 'New Text');
        
        final result = repository.loadJournalEntry('2026-04-29');
        expect(result, 'New Text');
      });
      
      test('deleteJournalEntry clears cache', () async {
        storage.boxes['journal']!['2026-04-29'] = {'text': 'To be deleted', 'timestamp': '...'};

        // Load into cache
        repository.loadJournalEntry('2026-04-29');
        
        // Delete
        await repository.deleteJournalEntry('2026-04-29');
        expect(storage.boxes['journal']!['2026-04-29'], isNull);

        // Load again - should return null
        expect(repository.loadJournalEntry('2026-04-29'), isNull);
      });

      test('getAllJournalEntries performs full scan and populates cache', () {
        storage.boxes['journal']!['2026-04-28'] = {'text': 'Text 1', 'timestamp': '2026-04-28'};
        storage.boxes['journal']!['2026-04-29'] = {'text': 'Text 2', 'timestamp': '2026-04-29'};

        final result = repository.getAllJournalEntries();

        expect(result.length, 2);
        expect(result['2026-04-28']!['text'], 'Text 1');
        expect(result['2026-04-29']!['text'], 'Text 2');
      });
    });

    group('Owl Protocol', () {
      test('Completing first task cancels nudge chain', () async {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        when(() => mockNotificationService.cancelNudgeChain(any())).thenAnswer((_) async => {});

        // Initial state: empty (nothing completed)
        final state = {'task1': true};
        await repository.saveCompletionState('morning', state);

        verify(() => mockNotificationService.cancelNudgeChain('morning')).called(1);
      });

      test('Uncompleting all tasks re-schedules nudge chain', () async {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        // Initial state: something was completed
        storage.boxes['activity']!['completion_morning_2026-04-30'] = {'task1': true};
        storage.boxes['routines']!['morning_start_time'] = '08:00';
        
        when(() => mockNotificationService.scheduleNudgeChain(
          routineId: any(named: 'routineId'),
          startTime: any(named: 'startTime'),
          title: any(named: 'title'),
        )).thenAnswer((_) async => {});

        // Action: uncheck everything
        final state = {'task1': false};
        await repository.saveCompletionState('morning', state);

        verify(() => mockNotificationService.scheduleNudgeChain(
          routineId: 'morning',
          startTime: any(named: 'startTime'),
          title: any(named: 'title'),
        )).called(1);
      });

      test('Saving routine start time schedules nudges', () async {
        when(() => mockNotificationService.scheduleNudgeChain(
          routineId: any(named: 'routineId'),
          startTime: any(named: 'startTime'),
          title: any(named: 'title'),
        )).thenAnswer((_) async => {});

        await repository.saveRoutineStartTime('morning', '07:30');

        expect(storage.boxes['routines']!['morning_start_time'], '07:30');
        verify(() => mockNotificationService.scheduleNudgeChain(
          routineId: 'morning',
          startTime: any(named: 'startTime'),
          title: any(named: 'title'),
        )).called(1);
      });

      test('syncStreaks resets streak if missed more than 1 day', () async {
        storage.boxes['activity']!['morning_last_streak_date'] = '2026-04-28';
        storage.boxes['activity']!['morning_streak_count'] = 5;
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');

        await repository.syncStreaks('morning');

        expect(storage.boxes['activity']!['morning_streak_count'], 0);
      });

      test('syncStreaks keeps streak if last completed yesterday', () async {
        storage.boxes['activity']!['morning_last_streak_date'] = '2026-04-29';
        storage.boxes['activity']!['morning_streak_count'] = 5;
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');

        await repository.syncStreaks('morning');

        expect(storage.boxes['activity']!['morning_streak_count'], 5);
      });
    });
  });
}
