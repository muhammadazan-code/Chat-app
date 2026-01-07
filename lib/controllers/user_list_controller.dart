import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/enums/user_relation_status.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/friendship_request_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class UsersListController extends GetxController {
  final FirestoreServices _firestoreServices = FirestoreServices();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController searchController = TextEditingController();
  final Uuid _uuid = Uuid();

  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _error = ''.obs;

  final RxMap<String, UserRelationshipsStatus> _userRelationships =
      <String, UserRelationshipsStatus>{}.obs;
  final RxList<FriendshipRequestModel> _sendRequests =
      <FriendshipRequestModel>[].obs;
  final RxList<FriendshipRequestModel> _receiveRequests =
      <FriendshipRequestModel>[].obs;

  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  List<UserModel> get user => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  String get error => _error.value;

  Map<String, UserRelationshipsStatus> get userRelationships =>
      _userRelationships;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRelationships();

    ever(_searchQuery, (_) => _filterUsers());
  }

  void _loadUsers() async {
    _users.bindStream(_firestoreServices.getAllUsersStream());
    // filter out current users and update the filtered list
    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      final otherUsers = userList
          .where((user) => user.id != currentUserId)
          .toList();

      if (_searchQuery.isEmpty) {
        _filteredUsers.value = otherUsers;
      } else {
        _filterUsers();
      }
    });
  }

  void _loadRelationships() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      // Load sent friend request
      _sendRequests.bindStream(
        _firestoreServices.getSentFriendRequestStream(currentUserId),
      );
      // Load received friend request
      _receiveRequests.bindStream(
        _firestoreServices.getFriendRequestStream(currentUserId),
      );

      // Load friends/friendship
      _friendships.bindStream(
        _firestoreServices.getFriendStream(currentUserId),
      );

      // Update relationship status whenever any of the list change
      ever(_sendRequests, (_) => _updateAllRelationshipsStatus());
      ever(_receiveRequests, (_) => _updateAllRelationshipsStatus());
      ever(_friendships, (_) => _updateAllRelationshipsStatus());
      ever(_users, (_) => _updateAllRelationshipsStatus());
    }
  }

  void _updateAllRelationshipsStatus() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return;

    for (var user in _users) {
      if (user.id != currentUserId) {
        final status = _calculateUserRelationshipStatus(user.id);
        _userRelationships[user.id] = status;
      }
    }
  }

  UserRelationshipsStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return UserRelationshipsStatus.none;

    // Check if they are friends
    final friendship = _friendships.firstWhereOrNull(
      (f) =>
          (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );

    if (friendship != null) {
      if (friendship.isBlocked) {
        return UserRelationshipsStatus.blocked;
      } else {
        return UserRelationshipsStatus.friends;
      }
    }

    final sentRequest = _sendRequests.firstWhereOrNull(
      (r) =>
          r.receiverId == userId && r.status == FriendshipRequestStatus.pending,
    );
    if (sentRequest != null) {
      return UserRelationshipsStatus.friendRequestSent;
    }

    // Check if there is a pending friend request from the user.
    final receivedRequest = _receiveRequests.firstWhereOrNull(
      (test) =>
          test.senderId == userId &&
          test.status == FriendshipRequestStatus.pending,
    );

    if (receivedRequest != null) {
      return UserRelationshipsStatus.friendRequestReceived;
    }
    return UserRelationshipsStatus.none;
  }

  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredUsers.value = _users
          .where((user) => user.id != currentUserId)
          .toList();
    } else {
      _filteredUsers.value = _users.where((user) {
        return user.id != currentUserId &&
            (user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearch() {
    _searchQuery.value = '';
  }

  Future<void> sendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        final request = FriendshipRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
        );

        _userRelationships[user.id] = UserRelationshipsStatus.friendRequestSent;
        await _firestoreServices.sendFriendRequest(request);
      }
      Get.snackbar('Success', 'Friend Request send to ${user.displayName}');
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipsStatus.none;
      _error.value = e.toString();
      if (kDebugMode) {
        print("Error Sending friend request: $e");
      }
      Get.snackbar('Error', "Failed to send friend request");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sendRequests.firstWhereOrNull(
          (r) =>
              r.receiverId == user.id &&
              r.status == FriendshipRequestStatus.pending,
        );
        if (request != null) {
          _userRelationships[user.id] = UserRelationshipsStatus.none;
          await _firestoreServices.cancelFriendRequest(request.id);
          Get.snackbar('Success', 'Friend Request Cancelled.');
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipsStatus.friendRequestSent;
      _error.value = e.toString();
      if (kDebugMode) {
        print("Error Cancelling Friend Request: $e");
      }
      Get.snackbar('Error', 'Failed to cancel friend request');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receiveRequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id &&
              r.status == FriendshipRequestStatus.pending,
        );
        if (request != null) {
          _userRelationships[user.id] = UserRelationshipsStatus.friends;
          await _firestoreServices.respondToFriendRequest(
            request.id,
            FriendshipRequestStatus.accepted,
          );
          Get.snackbar('Success', 'Friend Request Accepted.');
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationshipsStatus.friendRequestReceived;
      _error.value = e.toString();
      if (kDebugMode) {
        print("Error Accept Friend Request: $e");
      }
      Get.snackbar('Error', 'Failed to accept friend request');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declinedFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receiveRequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id &&
              r.status == FriendshipRequestStatus.pending,
        );
        if (request != null) {
          _userRelationships[user.id] = UserRelationshipsStatus.none;
          await _firestoreServices.respondToFriendRequest(
            request.id,
            FriendshipRequestStatus.declined,
          );
          Get.snackbar('Success', 'Friend Request Declined.');
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationshipsStatus.friendRequestReceived;
      _error.value = e.toString();
      if (kDebugMode) {
        print("Error Declined Friend Request: $e");
      }
      Get.snackbar('Error', 'Failed to decline friend request');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final relationship =
            _userRelationships[user.id] ?? UserRelationshipsStatus.none;
        if (relationship != UserRelationshipsStatus.friends) {
          Get.snackbar(
            "Info",
            'You can only chat with friends. Please send a friend request first.',
          );
          return;
        }
        final chatId = await _firestoreServices.createOrGetChat(
          currentUserId,
          user.id,
        );
        Get.toNamed(
          AppRoutes.chatView,
          arguments: {'chatId': chatId, 'otherUser': user},
        );
      }
    } catch (e) {
      _error.value = e.toString();
      if (kDebugMode) {
        print('Error starting chat: $e');
      }
      Get.snackbar('Error', 'Failed to start chat');
    } finally {
      _isLoading.value = false;
    }
  }

  UserRelationshipsStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationshipsStatus.none;
  }

  String getRelationshipButtonText(UserRelationshipsStatus status) {
    switch (status) {
      case UserRelationshipsStatus.none:
        return 'Add';
      case UserRelationshipsStatus.friendRequestSent:
        return 'Request sent';
      case UserRelationshipsStatus.friendRequestReceived:
        return 'Accept';
      case UserRelationshipsStatus.friends:
        return 'Message';
      case UserRelationshipsStatus.blocked:
        return 'Blocked';
    }
  }

  IconData getRelationshipButtonIcon(UserRelationshipsStatus status) {
    switch (status) {
      case UserRelationshipsStatus.none:
        return Icons.person_add;
      case UserRelationshipsStatus.friendRequestSent:
        return Icons.access_time;
      case UserRelationshipsStatus.friendRequestReceived:
        return Icons.check;
      case UserRelationshipsStatus.friends:
        return Icons.chat_bubble_outline;
      case UserRelationshipsStatus.blocked:
        return Icons.block;
    }
  }

  Color getRelationshipButtonColor(UserRelationshipsStatus status) {
    switch (status) {
      case UserRelationshipsStatus.none:
        return Colors.blue;
      case UserRelationshipsStatus.friendRequestSent:
        return Colors.orange;
      case UserRelationshipsStatus.friendRequestReceived:
        return Colors.green;
      case UserRelationshipsStatus.friends:
        return Colors.blue;
      case UserRelationshipsStatus.blocked:
        return Colors.redAccent;
    }
  }

  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);

    switch (status) {
      case UserRelationshipsStatus.none:
        sendFriendRequest(user);
        break;
      case UserRelationshipsStatus.friendRequestReceived:
        acceptFriendRequest(user);
        break;
      case UserRelationshipsStatus.friendRequestSent:
        cancelFriendRequest(user);
        break;
      case UserRelationshipsStatus.friends:
        startChat(user);
        break;
      case UserRelationshipsStatus.blocked:
        Get.snackbar('Info', 'You have blocked this user.');
        break;
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return 'Online';
    } else {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);

      if (difference.inMinutes < 1) {
        return 'Just now.';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes} m ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours} h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inHours} d ago';
      } else {
        return 'Last seen ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}}';
      }
    }
  }

  void clearError() {
    _error.value = '';
  }
}
