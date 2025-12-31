class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessgeSenderId;
  final Map<String, int> unreadCount;
  final Map<String, bool> deletedBy;
  final Map<String, DateTime?> deletedAt;
  final Map<String, DateTime?> lastSeenBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessgeSenderId,
    this.deletedBy = const {},
    required this.createdAt,
    this.lastMessageTime,
    required this.unreadCount,
    this.lastMessage,
    this.deletedAt = const {},
    this.lastSeenBy = const {},
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessgeSenderId,
      'deletedAt': deletedAt.map(
        (key, value) => MapEntry(key, value!.millisecondsSinceEpoch),
      ),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'lastSeenBy': lastSeenBy.map(
        (key, value) => MapEntry(key, value!.millisecondsSinceEpoch),
      ),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'deletedBy': deletedBy,
    };
  }

  static ChatModel fromMap(Map<String, dynamic> map) {
    Map<String, DateTime?> lastSeenMap = {};
    if (map['lastSeenBy'] != null) {
      Map<String, dynamic> rawLastSeen = Map<String, dynamic>.from(
        map['lastSeenBy'],
      );
      lastSeenMap = rawLastSeen.map(
        (key, value) => MapEntry(
          key,
          value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null,
        ),
      );
    }
    Map<String, DateTime?> deletedAtMap = {};
    if (map['deletedAt'] != null) {
      Map<String, dynamic> rawDeletedAt = Map<String, dynamic>.from(
        map['deletedAt'],
      );
      deletedAtMap = rawDeletedAt.map(
        (key, value) => MapEntry(
          key,
          value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null,
        ),
      );
    }
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants']),
      lastMessgeSenderId: map['lastMessgeSenderId'],
      createdAt: DateTime.fromMicrosecondsSinceEpoch(map['createdAt']),
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMicrosecondsSinceEpoch(map['lastMessageTime'])
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount']),
      lastMessage: map['lastMessage'],
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(map['updatedAt']),
      deletedAt: deletedAtMap,
      lastSeenBy: lastSeenMap,
    );
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? deletedBy,
    Map<String, DateTime?>? deletedAt,
    Map<String, DateTime?>? lastSeenBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessgeSenderId: lastMessgeSenderId ?? this.lastMessgeSenderId,
      createdAt: createdAt ?? this.createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherParticipants(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isDeletedBy(String userId) {
    return deletedBy[userId] ?? false;
  }

  DateTime? getDeletedAt(String userId) {
    return deletedAt[userId];
  }

  DateTime? getLastSeenBy(String userId) {
    return lastSeenBy[userId];
  }

  bool isMessageSeen(String currentUserId, String otherUserId) {
    if (lastMessgeSenderId == currentUserId) {
      final otherUserLastSeen = getLastSeenBy(otherUserId);
      if (otherUserLastSeen != null && lastMessageTime != null) {
        return otherUserLastSeen.isAfter(lastMessageTime!) ||
            otherUserLastSeen.isAtSameMomentAs(lastMessageTime!);
      }
    }
    return false;
  }
}
