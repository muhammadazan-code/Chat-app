enum NotificationsType {
  friendRequest,
  newMessage,
  friendRequestAccept,
  friendRequestDeclined,
  friendReceived,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationsType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'userId': userId,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'data': data,
    };
  }

  static NotificationModel fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationsType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationsType.friendRequest,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isRead: map['isRead'] ?? false,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationsType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
