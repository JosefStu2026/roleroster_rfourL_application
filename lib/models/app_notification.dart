// lib/models/app_notification.dart

class AppNotification {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final String taskId;
  final String groupId;
  final String actorId;
  final String actorName;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.taskId,
    required this.groupId,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      recipientId: map['recipientId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      taskId: map['taskId'] ?? '',
      groupId: map['groupId'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      readAt: DateTime.tryParse(map['readAt'] ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        'taskId': taskId,
        'groupId': groupId,
        'actorId': actorId,
        'actorName': actorName,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        taskId: taskId,
        groupId: groupId,
        actorId: actorId,
        actorName: actorName,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}
