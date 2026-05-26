// lib/models/group_model.dart

class GroupModel {
  final String id;
  final String name;
  final String title;
  final String leaderId;
  final String leaderName;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final Map<String, String> memberRoles;
  final int totalTasks;
  final int doneTasks;
  final DateTime startedAt;
  final DateTime dueAt;
  final DateTime createdAt;
  final bool archived;
  final DateTime? archivedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.title,
    required this.leaderId,
    required this.leaderName,
    required this.memberIds,
    required this.memberNames,
    required this.memberRoles,
    required this.totalTasks,
    required this.doneTasks,
    required this.startedAt,
    required this.dueAt,
    required this.createdAt,
    this.archived = false,
    this.archivedAt,
  });

  double get progress => totalTasks == 0 ? 0 : doneTasks / totalTasks;

  int get memberCount => memberIds.length;

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      leaderId: map['leaderId'] ?? '',
      leaderName: map['leaderName'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberNames: Map<String, String>.from(map['memberNames'] ?? const {}),
      memberRoles: Map<String, String>.from(map['memberRoles'] ?? const {}),
      totalTasks: (map['totalTasks'] ?? 0) as int,
      doneTasks: (map['doneTasks'] ?? 0) as int,
      startedAt: DateTime.tryParse(map['startedAt'] ?? '') ?? DateTime.now(),
      dueAt: DateTime.tryParse(map['dueAt'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      archived: map['archived'] == true,
      archivedAt: map['archivedAt'] == null
          ? null
          : DateTime.tryParse(map['archivedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'title': title,
        'leaderId': leaderId,
        'leaderName': leaderName,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'memberRoles': memberRoles,
        'totalTasks': totalTasks,
        'doneTasks': doneTasks,
        'startedAt': startedAt.toIso8601String(),
        'dueAt': dueAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
        'archivedAt': archivedAt?.toIso8601String(),
      };
}
