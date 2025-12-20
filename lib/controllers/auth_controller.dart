import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthServices _authService = AuthServices();
  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _isInitialized = false.obs;
  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _user.value != null;
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_authService.authStateChanges);
    // ever(_user, _handleAuthStateChange);
  }

  // void _handleAuthStateChange(User? user) {
  //   if (user == null) {
  //     if (Get.currentRoute != AppRoutes.loginView) {
  //       Get.offAllNamed(AppRoutes.loginView);
  //     }
  //   } else {
  //     if (Get.currentRoute != AppRoutes.profile) {
  //       Get.offAllNamed(AppRoutes.profile);
  //     }
  //   }
  //   if (!_isInitialized.value) {
  //     _isInitialized.value = true;
  //   }
  // }

  // void checkInitialAuthState() {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   if (currentUser != null) {
  //     _user.value = currentUser;
  //     Get.offAllNamed(AppRoutes.mainView);
  //   } else {
  //     Get.offAllNamed(AppRoutes.loginView);
  //   }
  //   _isInitialized.value = true;
  // }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = "";
      UserModel? userModel = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userModel != null) {
        _userModel.value = userModel;
        Get.offAllNamed(AppRoutes.profileView);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Login');
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading.value = true;
      _error.value = "";
      UserModel? userModel = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (userModel != null) {
        _userModel.value = userModel;
        Get.offAllNamed(AppRoutes.loginView);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Create Account');
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      await _authService.signOut();
      _userModel.value = null;
      Get.offAllNamed(AppRoutes.loginView);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Sign out.');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      await _authService.delete();
      _userModel.value = null;
      Get.offAllNamed(AppRoutes.loginView);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Delete Account.');
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _error.value = '';
  }
}
