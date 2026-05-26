// lib/models/group_model.dart

class GroupModel {
  final String id;
  final String name;
  final String leaderId;
  final String leaderName;
  final List<String> memberIds;
  final int totalTasks;
  final int doneTasks;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.leaderName,
    required this.memberIds,
    required this.totalTasks,
    required this.doneTasks,
    required this.createdAt,
  });

  double get progress =>
      totalTasks == 0 ? 0 : doneTasks / totalTasks;

  int get memberCount => memberIds.length;

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id:          id,
      name:        map['name']        ?? '',
      leaderId:    map['leaderId']    ?? '',
      leaderName:  map['leaderName']  ?? '',
      memberIds:   List<String>.from(map['memberIds'] ?? []),
      totalTasks:  (map['totalTasks'] ?? 0) as int,
      doneTasks:   (map['doneTasks']  ?? 0) as int,
      createdAt:   DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name':        name,
    'leaderId':    leaderId,
    'leaderName':  leaderName,
    'memberIds':   memberIds,
    'totalTasks':  totalTasks,
    'doneTasks':   doneTasks,
    'createdAt':   createdAt.toIso8601String(),
  };
}
