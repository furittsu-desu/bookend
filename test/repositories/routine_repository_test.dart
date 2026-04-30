import 'dart:convert';
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
      final tasks = [RoutineTask(title: 'Morning')];
      when(() => mockPrefs.getString('morning_tasks'))
          .thenReturn(jsonEncode(tasks.map((t) => t.toJson()).toList()));
      
      final result = repository.loadMorningTasks();
      expect(result.first.title, 'Morning');
    });

    test('loadNightTasks returns tasks from prefs', () {
      final tasks = [RoutineTask(title: 'Night')];
      when(() => mockPrefs.getString('night_tasks'))
          .thenReturn(jsonEncode(tasks.map((t) => t.toJson()).toList()));
      
      final result = repository.loadNightTasks();
      expect(result.first.title, 'Night');
    });

    test('saveMorningTasks saves JSON to prefs', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      final tasks = [RoutineTask(title: 'Test')];
      
      await repository.saveMorningTasks(tasks);
      verify(() => mockPrefs.setString('morning_tasks', any())).called(1);
    });

    test('saveNightTasks saves JSON to prefs', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      final tasks = [RoutineTask(title: 'Test Night')];
      
      await repository.saveNightTasks(tasks);
      verify(() => mockPrefs.setString('night_tasks', any())).called(1);
    });

    group('Completion State', () {
      test('saveCompletionState saves JSON to prefs with date key', () async {
        when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        
        final state = {'task-id': true};
        await repository.saveCompletionState('morning', state);
        
        verify(() => mockPrefs.setString('completion_morning_2026-04-30', jsonEncode(state))).called(1);
      });

      test('loadCompletionState returns map from prefs', () {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        final state = {'task-id': true};
        when(() => mockPrefs.getString('completion_morning_2026-04-30')).thenReturn(jsonEncode(state));
        
        final result = repository.loadCompletionState('morning');
        expect(result['task-id'], true);
      });

      test('loadCompletionState returns empty map if not set', () {
        when(() => mockTimeService.getEffectiveDateString()).thenReturn('2026-04-30');
        when(() => mockPrefs.getString('completion_morning_2026-04-30')).thenReturn(null);
        
        final result = repository.loadCompletionState('morning');
        expect(result, isEmpty);
      });
    });

    test('getStreak returns value from prefs', () {
      when(() => mockPrefs.getInt('morning_streak_count')).thenReturn(5);
      expect(repository.getStreak('morning'), 5);
    });

    test('incrementStreak updates count and date', () async {
      when(() => mockPrefs.getInt(any())).thenReturn(5);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      
      await repository.incrementStreak('morning', '2026-04-29');
      
      verify(() => mockPrefs.setInt('morning_streak_count', 6)).called(1);
      verify(() => mockPrefs.setString('morning_last_streak_date', '2026-04-29')).called(1);
    });

    test('resetStreak sets count to zero', () async {
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      
      await repository.resetStreak('morning');
      
      verify(() => mockPrefs.setInt('morning_streak_count', 0)).called(1);
    });

    group('removeStreakForToday', () {
      test('removes streak if date matches', () async {
        when(() => mockPrefs.getString('morning_last_streak_date')).thenReturn('2026-04-30');
        when(() => mockPrefs.getInt('morning_streak_count')).thenReturn(5);
        when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
        when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

        await repository.removeStreakForToday('morning', '2026-04-30');

        verify(() => mockPrefs.setInt('morning_streak_count', 4)).called(1);
        verify(() => mockPrefs.setString('morning_last_streak_date', '')).called(1);
      });

      test('does nothing if date does not match', () async {
        when(() => mockPrefs.getString('morning_last_streak_date')).thenReturn('2026-04-29');
        
        await repository.removeStreakForToday('morning', '2026-04-30');

        verifyNever(() => mockPrefs.setInt(any(), any()));
        verifyNever(() => mockPrefs.remove(any()));
      });
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

      test('loadJournalEntry returns raw string when not valid JSON (fallback)', () {
        final raw = 'Just a raw string entry';
        when(() => mockPrefs.getString('journal_2026-04-29')).thenReturn(raw);
        
        expect(repository.loadJournalEntry('2026-04-29'), 'Just a raw string entry');
      });

      test('loadJournalEntry returns raw string when JSON is a list (fallback)', () {
        final json = '["item1", "item2"]';
        when(() => mockPrefs.getString('journal_2026-04-29')).thenReturn(json);
        
        expect(repository.loadJournalEntry('2026-04-29'), '["item1", "item2"]');
      });

      test('loadJournalEntry returns raw string when text field is missing (fallback)', () {
        final json = '{"not_text":"some data"}';
        when(() => mockPrefs.getString('journal_2026-04-29')).thenReturn(json);
        
        expect(repository.loadJournalEntry('2026-04-29'), '{"not_text":"some data"}');
      });

      test('loadJournalEntry hits cache on subsequent calls', () {
        final json = '{"text":"Cached entry","timestamp":"..."}';
        when(() => mockPrefs.getString(any())).thenReturn(json);
        
        // First call - populates cache
        repository.loadJournalEntry('2026-04-29');
        verify(() => mockPrefs.getString('journal_2026-04-29')).called(1);
        
        // Second call - should hit cache
        final result = repository.loadJournalEntry('2026-04-29');
        expect(result, 'Cached entry');
        verifyNever(() => mockPrefs.getString('journal_2026-04-29'));
      });

      test('saveJournalEntry updates cache', () async {
        when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
        
        await repository.saveJournalEntry('2026-04-29', 'New Text');
        
        // Should hit cache, not prefs
        final result = repository.loadJournalEntry('2026-04-29');
        expect(result, 'New Text');
        verifyNever(() => mockPrefs.getString('journal_2026-04-29'));
      });
      
      test('deleteJournalEntry clears cache', () async {
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
        final json = '{"text":"To be deleted","timestamp":"..."}';
        when(() => mockPrefs.getString(any())).thenReturn(json);

        // Load into cache
        repository.loadJournalEntry('2026-04-29');
        
        // Delete
        await repository.deleteJournalEntry('2026-04-29');
        verify(() => mockPrefs.remove('journal_2026-04-29')).called(1);

        // Load again - should call prefs because cache is cleared
        repository.loadJournalEntry('2026-04-29');
        verify(() => mockPrefs.getString('journal_2026-04-29')).called(2);
      });

      test('getAllJournalEntries performs full scan and populates cache', () {
        final journalKeys = ['journal_2026-04-28', 'journal_2026-04-29'];
        when(() => mockPrefs.getKeys()).thenReturn(journalKeys.toSet());
        when(() => mockPrefs.getString('journal_2026-04-28')).thenReturn('Raw Text');
        when(() => mockPrefs.getString('journal_2026-04-29')).thenReturn('{"text":"JSON Text","timestamp":"..."}');

        final result = repository.getAllJournalEntries();

        expect(result.length, 2);
        expect(result['2026-04-28']!['text'], 'Raw Text');
        expect(result['2026-04-29']!['text'], 'JSON Text');
        
        // Subsequent call should return same cache without scanning
        final result2 = repository.getAllJournalEntries();
        expect(result2, same(result));
        verify(() => mockPrefs.getKeys()).called(1);
      });
    });
  });
}
