import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'routine_task.g.dart';

const _uuid = Uuid();

@HiveType(typeId: 0)
class RoutineTask {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String emoji;
  @HiveField(3)
  bool isCompleted;
  @HiveField(4)
  int targetDuration; // in seconds, 0 means not set
  @HiveField(5)
  int previousTargetDuration; // for undo
  @HiveField(6)
  int? lastFocusDuration; // added to store focus duration if task is unchecked

  RoutineTask({
    String? id,
    required this.title,
    this.emoji = '',
    this.isCompleted = false,
    this.targetDuration = 0,
    this.previousTargetDuration = 0,
    this.lastFocusDuration,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'isCompleted': isCompleted,
        'targetDuration': targetDuration,
        'previousTargetDuration': previousTargetDuration,
        'lastFocusDuration': lastFocusDuration,
      };

  factory RoutineTask.fromJson(Map<String, dynamic> json) => RoutineTask(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        targetDuration: json['targetDuration'] as int? ?? 0,
        previousTargetDuration: json['previousTargetDuration'] as int? ?? 0,
        lastFocusDuration: json['lastFocusDuration'] as int?,
      );

  RoutineTask copyWith({
    String? title,
    String? emoji,
    bool? isCompleted,
    int? targetDuration,
    int? previousTargetDuration,
    int? lastFocusDuration,
  }) =>
      RoutineTask(
        id: id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        isCompleted: isCompleted ?? this.isCompleted,
        targetDuration: targetDuration ?? this.targetDuration,
        previousTargetDuration: previousTargetDuration ?? this.previousTargetDuration,
        lastFocusDuration: lastFocusDuration ?? this.lastFocusDuration,
      );
}
