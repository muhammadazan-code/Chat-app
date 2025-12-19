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
}
