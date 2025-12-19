import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreServices _firestoreServices = FirestoreServices();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _firestoreServices.updateUserOnlineStatus(user.uid, true);
        return await _firestoreServices.getUser(user.uid);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to Sign In: ${e.toString()}");
    }
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        final userModel = UserModel(
          id: user.uid,
          email: email,
          photoUrl: '',
          isOnline: true,
          displayName: displayName,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await _firestoreServices.createUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception("Failed to Register: ${e.toString()}");
    }
  }

  Future<void> sendPasswordsResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Failed to Send Password Reset Email: ${e.toString()}");
    }
  }

  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _firestoreServices.updateUserOnlineStatus(currentUserId!, false);
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception("Failed to Sign Out: ${e.toString()}");
    }
  }

  Future<void> delete() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestoreServices.deleteUser(user.uid);
        await user.delete();
      }
    } catch (e) {
      throw Exception("Failed To Delete Account: ${e.toString()}");
    }
  }
}
