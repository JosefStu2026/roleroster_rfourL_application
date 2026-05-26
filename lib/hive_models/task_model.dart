// lib/hive_models/task_model.dart
//
// This file includes a manual Hive adapter and does not require generated code.

import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String groupId;
  @HiveField(2)
  late String groupName;
  @HiveField(3)
  late String title;
  @HiveField(4)
  late String assignedToId;
  @HiveField(5)
  late String assignedToName;
  @HiveField(6)
  late String status;
  @HiveField(7)
  late String role;
  @HiveField(8)
  late String deadline;
  @HiveField(9)
  late String createdAt;

  TaskModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.assignedToId,
    required this.assignedToName,
    required this.status,
    required this.role,
    required this.deadline,
    required this.createdAt,
  });
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return TaskModel(
      id: fields[0] as String,
      groupId: fields[1] as String,
      groupName: fields[2] as String,
      title: fields[3] as String,
      assignedToId: fields[4] as String,
      assignedToName: fields[5] as String,
      status: fields[6] as String,
      role: fields[7] as String,
      deadline: fields[8] as String,
      createdAt: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.groupName)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.assignedToId)
      ..writeByte(5)
      ..write(obj.assignedToName)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.role)
      ..writeByte(8)
      ..write(obj.deadline)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
