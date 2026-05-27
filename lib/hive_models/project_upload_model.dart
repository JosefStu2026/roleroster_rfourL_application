// lib/hive_models/project_upload_model.dart

import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class ProjectUploadModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String ownerId;
  @HiveField(2)
  late String ownerName;
  @HiveField(3)
  late String fileName;
  @HiveField(4)
  late String groupName;
  @HiveField(5)
  late String taskTitle;
  @HiveField(6)
  late String fileUrl;
  @HiveField(7)
  late String storagePath;
  @HiveField(8)
  late String fileType;
  @HiveField(9)
  late String createdAt;

  ProjectUploadModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.fileName,
    required this.groupName,
    required this.taskTitle,
    required this.fileUrl,
    required this.storagePath,
    required this.fileType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'fileName': fileName,
        'groupName': groupName,
        'taskTitle': taskTitle,
        'fileUrl': fileUrl,
        'storagePath': storagePath,
        'fileType': fileType,
        'createdAt': createdAt,
      };

  factory ProjectUploadModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectUploadModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      fileName: map['fileName'] ?? '',
      groupName: map['groupName'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      storagePath: map['storagePath'] ?? '',
      fileType: map['fileType'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }
}

class ProjectUploadModelAdapter extends TypeAdapter<ProjectUploadModel> {
  @override
  final int typeId = 1;

  @override
  ProjectUploadModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ProjectUploadModel(
      id: fields[0] as String,
      ownerId: fields[1] as String,
      ownerName: fields[2] as String,
      fileName: fields[3] as String,
      groupName: fields[4] as String,
      taskTitle: fields[5] as String,
      fileUrl: fields[6] as String,
      storagePath: fields[7] as String,
      fileType: fields[8] as String,
      createdAt: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectUploadModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerId)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.fileName)
      ..writeByte(4)
      ..write(obj.groupName)
      ..writeByte(5)
      ..write(obj.taskTitle)
      ..writeByte(6)
      ..write(obj.fileUrl)
      ..writeByte(7)
      ..write(obj.storagePath)
      ..writeByte(8)
      ..write(obj.fileType)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectUploadModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}