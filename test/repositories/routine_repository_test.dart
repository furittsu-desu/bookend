import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookend/repositories/routine_repository.dart';
import 'package:bookend/services/time_service.dart';
import 'package:bookend/models/routine_task.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockTimeService extends Mock implements TimeService {}

void main() {
  late RoutineRepository repository;
  late MockSharedPreferences mockPrefs;
  late MockTimeService mockTimeService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockTimeService = MockTimeService();
    repository = RoutineRepository(mockPrefs, mockTimeService);
  });

  group('RoutineRepository', () {
    test('isOnboardingCompleted returns false if not set', () {
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      expect(repository.isOnboardingCompleted(), isFalse);
    });

    test('isOnboardingCompleted returns true if set to true', () {
      when(() => mockPrefs.getBool('onboarding_completed')).thenReturn(true);
      expect(repository.isOnboardingCompleted(), isTrue);
    });

    test('completeOnboarding sets flag', () async {
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      await repository.completeOnboarding();

      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });

    test('loadMorningTasks returns tasks from prefs', () {
      final json = '[{"id":"1","title":"Task","emoji":"🔥","isCompleted":false}]';
      when(() => mockPrefs.getString('morning_tasks')).thenReturn(json);
      
      final tasks = repository.loadMorningTasks();
      
      expect(tasks.length, 1);
      expect(tasks[0].title, 'Task');
    });

    test('saveMorningTasks saves JSON to prefs', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      
      await repository.saveMorningTasks([RoutineTask(title: 'New', emoji: '🆕')]);
      
      verify(() => mockPrefs.setString('morning_tasks', any())).called(1);
    });

    test('getStreak returns value from prefs', () {
      when(() => mockPrefs.getInt('morning_streak_count')).thenReturn(5);
      expect(repository.getStreak('morning'), 5);
    });

    test('incrementStreak updates count and date', () async {
      when(() => mockPrefs.getInt(any())).thenReturn(2);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      await repository.incrementStreak('morning', '2026-04-29');

      verify(() => mockPrefs.setInt('morning_streak_count', 3)).called(1);
      verify(() => mockPrefs.setString('morning_last_streak_date', '2026-04-29')).called(1);
    });

    group('Journal', () {
      test('loadJournalEntry returns null when no entry exists', () {
        when(() => mockPrefs.getString(any())).thenReturn(null);
        expect(repository.loadJournalEntry('2026-04-29'), isNull);
      });

      test('loadJournalEntry returns text from valid JSON entry', () {
        final json = '{"text":"Hello World","timestamp":"2026-04-29T12:00:00"}';
        when(() => mockPrefs.getString('journal_2026-04-29')).thenReturn(json);
        
        expect(repository.loadJournalEntry('2026-04-29'), 'Hello World');
      });
    });
  });
}
