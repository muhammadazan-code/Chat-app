enum FriendshipRequestStatus { pending, accepted, declined }

class FriendshipRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendshipRequestStatus status;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final String? message;

  FriendshipRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendshipRequestStatus.pending,
    this.respondedAt,
    required this.createdAt,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'message': message,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  static FriendshipRequestModel fromMap(Map<String, dynamic> map) {
    return FriendshipRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      respondedAt: DateTime.fromMillisecondsSinceEpoch(map['respondedAt']),
      message: map['message'],
      status: FriendshipRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendshipRequestStatus.pending,
      ),
    );
  }

  FriendshipRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    FriendshipRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendshipRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
