import 'package:flutter_test/flutter_test.dart';
import 'package:bookend/models/routine_task.dart';

void main() {
  group('RoutineTask', () {
    test('should generate a unique ID if none is provided', () {
      final task1 = RoutineTask(title: 'Task 1');
      final task2 = RoutineTask(title: 'Task 2');

      expect(task1.id, isNotEmpty);
      expect(task2.id, isNotEmpty);
      expect(task1.id, isNot(equals(task2.id)));
    });

    test('should use provided ID', () {
      final task = RoutineTask(id: 'custom-id', title: 'Task');
      expect(task.id, 'custom-id');
    });

    test('toJson should return valid map', () {
      final task = RoutineTask(
        id: '123',
        title: 'Test Task',
        emoji: '🧪',
        isCompleted: true,
        targetDuration: 300,
        previousTargetDuration: 60,
        lastFocusDuration: 120,
      );

      final json = task.toJson();

      expect(json['id'], '123');
      expect(json['title'], 'Test Task');
      expect(json['emoji'], '🧪');
      expect(json['isCompleted'], true);
      expect(json['targetDuration'], 300);
      expect(json['previousTargetDuration'], 60);
      expect(json['lastFocusDuration'], 120);
    });

    test('fromJson should create valid object', () {
      final json = {
        'id': '456',
        'title': 'Json Task',
        'emoji': '📊',
        'isCompleted': false,
        'targetDuration': 0,
        'previousTargetDuration': 0,
        'lastFocusDuration': null,
      };

      final task = RoutineTask.fromJson(json);

      expect(task.id, '456');
      expect(task.title, 'Json Task');
      expect(task.emoji, '📊');
      expect(task.isCompleted, false);
      expect(task.targetDuration, 0);
      expect(task.previousTargetDuration, 0);
      expect(task.lastFocusDuration, isNull);
    });

    test('copyWith should create updated object', () {
      final task = RoutineTask(title: 'Original');
      
      final updated = task.copyWith(
        title: 'Updated',
        isCompleted: true,
      );

      expect(updated.id, task.id);
      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true);
      expect(updated.emoji, task.emoji);
    });
  });
}
