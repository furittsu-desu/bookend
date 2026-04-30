// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineTaskAdapter extends TypeAdapter<RoutineTask> {
  @override
  final int typeId = 0;

  @override
  RoutineTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineTask(
      id: fields[0] as String?,
      title: fields[1] as String,
      emoji: fields[2] as String,
      isCompleted: fields[3] as bool,
      targetDuration: fields[4] as int,
      previousTargetDuration: fields[5] as int,
      lastFocusDuration: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineTask obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.targetDuration)
      ..writeByte(5)
      ..write(obj.previousTargetDuration)
      ..writeByte(6)
      ..write(obj.lastFocusDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
