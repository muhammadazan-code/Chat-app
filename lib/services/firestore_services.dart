import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/friendship_request_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// This below method store the details of the user on Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('Users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception("Failed To Create User: ${e.toString()}");
    }
  }

  // Get the data from the firestore
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to Get User: ${e.toString()}");
    }
  }

  // Update the status of the user when was online and when was not.
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection("Users")
          .doc(userId)
          .get();
      if (doc.exists) {
        await _firestore.collection('Users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now(),
        });
      }
    } catch (e) {
      throw Exception("Failed to Update User Online Status: ${e.toString()}");
    }
  }
  // Delete the user record from the firestore

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection("Users").doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to Delete User: ${e.toString()}');
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('Users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to Update User');
    }
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendFriendRequest(FriendshipRequestModel request) async {
    try {
      await _firestore
          .collection('FriendRequests')
          .doc(request.id)
          .set(request.toMap());

      String notificationId =
          "friend_request_${request.senderId}_${request.receiverId}_${DateTime.now().millisecondsSinceEpoch}";

      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          title: "New Friend Request",
          body: "You have received a new friend request",
          type: NotificationsType.friendRequest,
          createdAt: DateTime.now(),
          data: {
            'senderId': request.senderId,
            'recieverId': request.receiverId,
          },
        ),
      );
    } catch (e) {
      throw Exception("Failed to send Friend Request: ${e.toString()}");
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      DocumentSnapshot requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();
      if (requestDoc.exists) {
        FriendshipRequestModel request = FriendshipRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );
        await _firestore.collection('friendRequest').doc(requestId).delete();
        await deleteNotificationByTypeAndUser(
          request.receiverId,
          NotificationsType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception("Failed to Cancel Friend Request: ${e.toString()}");
    }
  }

  Future<void> respondToFriendRequest(
    String requestId,
    FriendshipRequestStatus status,
  ) async {
    try {
      await _firestore.collection("friendRequest").doc(requestId).update({
        'status': status.name,
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });
      DocumentSnapshot requestDoc = await _firestore
          .collection('friendRequest')
          .doc(requestId)
          .get();

      if (requestDoc.exists) {
        FriendshipRequestModel request = FriendshipRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );
        if (status == FriendshipRequestStatus.accepted) {
          await createNotification(
            NotificationModel(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Accepted',
              body: 'Your friend request has been accepted',
              type: NotificationsType.friendRequestAccept,
              createdAt: DateTime.now(),
              data: {'userId': request.receiverId},
            ),
          );
          await _removeNotificationForCancelRequest(
            request.receiverId,
            request.senderId,
          );
        } else if (status == FriendshipRequestStatus.declined) {
          // await cancelNotification(
          //   NotificationModel(
          //     id: DateTime.now().millisecondsSinceEpoch.toString(),
          //     userId: request.senderId,
          //     title: 'Friend Request Declined',
          //     body: 'Your friend request has been declined',
          //     type: NotificationsType.friendRequestDeclined,
          //     createdAt: DateTime.now(),
          //     data: {'userId': request.receiverId},
          //   ),
          // );
          await _removeNotificationForCancelRequest(
            request.receiverId,
            request.senderId,
          );
        }
      }
    } catch (e) {
      throw Exception("Failed to Respond to Friend Request ${e.toString()}");
    }
  }

  Stream<List<FriendshipRequestModel>> getFriendRequestStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendshipRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<FriendshipRequestModel>> getSentFriendRequestStream(
    String userId,
  ) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendshipRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<FriendshipRequestModel?> getFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (query.docs.isNotEmpty) {
        return FriendshipRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get friend request: ${e.toString()}");
    }
  }

  // FriendShips Collection
  Future<void> createFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userId = [user1Id, user2Id];
      userId.sort();

      String friendShipId = '${userId[0]}_${userId[1]}';

      FriendshipModel friendship = FriendshipModel(
        id: friendShipId,
        user1Id: userId[0],
        user2Id: userId[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .set(friendship.toMap());
    } catch (e) {
      throw Exception("Failed to create friendship: ${e.toString()}");
    }
  }

  Future<void> removeFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userId = [user1Id, user2Id];
      userId.sort();

      String friendShipId = '${userId[0]}_${userId[1]}';
      await _firestore.collection('friendships').doc(friendShipId).delete();
      await createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user2Id,
          title: "Friend Removed",
          body: 'You are no  longer friends.',
          type: NotificationsType.friendRemoved,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to remove friendship: ${e.toString()}');
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> usersId = [blockerId, blockedId];
      usersId.sort();

      String friendShipId = '${usersId[0]}_${usersId[1]}';
      await _firestore.collection('friendships').doc(friendShipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> unBlockUser(String blockerId, String blockedId) async {
    try {
      List<String> usersId = [blockerId, blockedId];
      usersId.sort();

      String friendShipId = '${usersId[0]}_${usersId[1]}';
      await _firestore.collection('friendships').doc(friendShipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  Stream<List<FriendshipModel>> getFriendStream(String userId) {
    return _firestore
        .collection('friendships')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot1) async {
          QuerySnapshot snapshot2 = await _firestore
              .collection('friendships')
              .where('user2Id', isEqualTo: userId)
              .get();

          List<FriendshipModel> friendShips = [];
          for (var doc in snapshot1.docs) {
            friendShips.add(FriendshipModel.fromMap(doc.data()));
          }
          for (var doc in snapshot2.docs) {
            friendShips.add(
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
            );
          }

          return friendShips.where((f) => !f.isBlocked).toList();
        });
  }

  Future<FriendshipModel?> getFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userId = [user1Id, user2Id];
      userId.sort();

      String friendShipId = '${userId[0]}_${userId[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();
      if (doc.exists) {
        return FriendshipModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friendships: ${e.toString()}');
    }
  }

  Future<bool> isUserBlocked(String userId, String otherUserID) async {
    try {
      List<String> userIds = [userId, otherUserID];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';
      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check if user is blocked: ${e.toString()}');
    }
  }

  Future<bool> isUnFriend(String userId, String otherUserID) async {
    try {
      List<String> userIds = [userId, otherUserID];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';
      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check if user is blocked: ${e.toString()}');
    }
  }

  // Chat Collection
  Future<String> createOrGetChat(String user1Id, String user2Id) async {
    try {
      List<String> participants = [user1Id, user2Id];
      participants.sort();

      String chatId = '${participants[0]}_${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        ChatModel newChat = ChatModel(
          id: chatId,
          participants: participants,
          lastMessgeSenderId: '',
          unreadCount: {user1Id: 0, user2Id: 0},
          lastMessage: '',
          deletedBy: {user1Id: false, user2Id: false},
          deletedAt: {user1Id: null, user2Id: null},
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
          lastSeenBy: {user1Id: DateTime.now(), user2Id: DateTime.now()},
        );
        await chatRef.set(newChat.toMap);
      } else {
        ChatModel existingChat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        if (existingChat.isDeletedBy(user1Id)) {
          await restoreChatForUser(chatId, user1Id);
        }
        if (existingChat.isDeletedBy(user2Id)) {
          await restoreChatForUser(chatId, user2Id);
        }
      }
      return chatId;
    } catch (e) {
      throw Exception("Failed to create or get chat: ${e.toString()}");
    }
  }

  Stream<List<ChatModel>> getUserChatStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .where((chat) => !chat.isDeletedBy(userId))
              .toList(),
        );
  }

  Future<void> updateChatLastMessage(
    String chatId,
    MessageModel message,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception("Failed to update chat last message: ${e.toString()} ");
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        "lastSeenBy": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception("Failed to update last seen: ${e.toString()}");
    }
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception("Failed to delete chat: ${e.toString()}");
    }
  }

  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': false,
      });
    } catch (e) {
      throw Exception("Failed to restore chat: ${e.toString()}");
    }
  }

  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': count,
      });
    } catch (e) {
      throw Exception("Failed to update unread count: ${e.toString()}");
    }
  }

  Future<void> restoreUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception("Failed to restore unread count: ${e.toString()}");
    }
  }

  // Message Collection
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      String chatId = await createOrGetChat(
        message.senderId,
        message.receiverId,
      );

      await updateChatLastMessage(chatId, message);

      await updateUserLastSeen(chatId, message.senderId);

      DocumentSnapshot chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        ChatModel chat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        int currentUnread = chat.getUnreadCount(message.receiverId);
        await updateUnreadCount(chatId, message.receiverId, currentUnread + 1);
      }
    } catch (e) {
      throw Exception("Failed to send message: ${e.toString()}");
    }
  }

  Stream<List<MessageModel>> getMessageStream(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> participants = [userId1, userId2];
          participants.sort();

          String chatId = '${participants[0]}_${participants[1]}';
          DocumentSnapshot chatDoc = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();
          ChatModel? chat;

          if (chatDoc.exists) {
            chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
          }
          List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            MessageModel message = MessageModel.fromMap(doc.data());
            if ((message.senderId == userId1 &&
                    message.receiverId == userId2) ||
                (message.senderId == userId2 &&
                    message.receiverId == userId1)) {
              bool includeMessage = true;
              if (chat != null) {
                DateTime? currentUserDeletedAt = chat.getDeletedAt(userId1);
                if (currentUserDeletedAt != null &&
                    message.timestamp.isBefore(currentUserDeletedAt)) {
                  includeMessage = false;
                }
              }
              if (includeMessage) {
                messages.add(message);
              }
            }
          }
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception("Failed to mark message as read: ${e.toString()}");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception("Failed to delete message: ${e.toString()}");
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception("Failed to edit message: ${e.toString()}");
    }
  }

  //Notification Collection
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception("Failed to create notification: ${e.toString()}");
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception("Failed to mark notification as read: ${e.toString()}");
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        "Failed to mark all notifications as read: ${e.toString()}",
      );
    }
  }

  Future<void> deleteNotificaions(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception("Failed to delete notification: ${e.toString()}");
    }
  }

  Future<void> deleteNotificationByTypeAndUser(
    String userId,
    NotificationsType notificationType,
    String relatedUserId,
  ) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: notificationType.name)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in notifications.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['data'] != null &&
            (data['data']['senderId'] == relatedUserId ||
                data['data']['userId' == relatedUserId])) {
          batch.delete(doc.reference);
        }
      }
    } catch (e) {
      throw Exception("Failed to delete notifications: ${e.toString()}");
    }
  }

  Future<void> _removeNotificationForCancelRequest(
    String receiverId,
    String senderId,
  ) async {
    try {
      await deleteNotificationByTypeAndUser(
        receiverId,
        NotificationsType.friendRequest,
        senderId,
      );
    } catch (e) {
      throw Exception("Failed to remove notificatins: ${e.toString()}");
    }
  }
}
