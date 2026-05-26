// lib/models/task_model.dart  (Firestore model — NOT the Hive one)

class TaskModel {
  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final String assignedToId;
  final String assignedToName;
  final String status;        // 'pending' | 'in_progress' | 'done' | 'archived'
  final String role;          // e.g. 'Backend', 'UI', 'Documentation'
  final DateTime deadline;
  final DateTime createdAt;

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

  bool get isDone     => status == 'done';
  bool get isArchived => status == 'archived';

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id:               id,
      groupId:          map['groupId']          ?? '',
      groupName:        map['groupName']         ?? '',
      title:            map['title']             ?? '',
      assignedToId:     map['assignedToId']      ?? '',
      assignedToName:   map['assignedToName']    ?? '',
      status:           map['status']            ?? 'pending',
      role:             map['role']              ?? '',
      deadline:  DateTime.tryParse(map['deadline']  ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'groupId':        groupId,
    'groupName':      groupName,
    'title':          title,
    'assignedToId':   assignedToId,
    'assignedToName': assignedToName,
    'status':         status,
    'role':           role,
    'deadline':       deadline.toIso8601String(),
    'createdAt':      createdAt.toIso8601String(),
  };

  TaskModel copyWith({String? status}) => TaskModel(
    id:             id,
    groupId:        groupId,
    groupName:      groupName,
    title:          title,
    assignedToId:   assignedToId,
    assignedToName: assignedToName,
    status:         status ?? this.status,
    role:           role,
    deadline:       deadline,
    createdAt:      createdAt,
  );
}
