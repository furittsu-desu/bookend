import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class RoutineTask {
  final String id;
  String title;
  String emoji;
  bool isCompleted;
  int targetDuration; // in seconds, 0 means not set
  int previousTargetDuration; // for undo
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
