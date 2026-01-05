import 'package:chat_app/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _obsecureCurrentPassword = true.obs;
  final RxBool _obsecureNewPassword = true.obs;
  final RxBool _obsecureConfirmPassword = true.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get obsecureConfirmPassword => _obsecureConfirmPassword.value;
  bool get obsecureCurrentPassword => _obsecureCurrentPassword.value;
  bool get obsecureNewPassword => _obsecureNewPassword.value;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toogleCurrentPasswordVisibility() {
    _obsecureCurrentPassword.value = !_obsecureCurrentPassword.value;
  }

  void toogleNewPasswordVisibility() {
    _obsecureNewPassword.value = !_obsecureNewPassword.value;
  }

  void toogleConfirmPasswordVisibility() {
    _obsecureConfirmPassword.value = !_obsecureConfirmPassword.value;
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;
    try {
      _isLoading.value = true;
      _error.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No User logged in");
      }
      final credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );
      if (kDebugMode) {
        print(credentials);
      }
      await user.reauthenticateWithCredential(credentials);
      await user.updatePassword(newPasswordController.text);

      Get.snackbar(
        'Success',
        "Password Changed Successfully",
        backgroundColor: Colors.green.withOpacity(.1),
        colorText: Colors.green,
        duration: Duration(seconds: 3),
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      Get.back();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = "New password is too weak";
          break;
        case "wrong-password":
          errorMessage = "Password is incorrect";
          break;
        case "requires-recent-login":
          errorMessage =
              "Please sign out and sign in again before changing password.";
          break;
        default:
          errorMessage = "Failed to change Password";
          break;
      }
      _error.value = errorMessage;
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(milliseconds: 4),
      );
    } catch (e) {
      _error.value = "Failed to Change Password";
      Get.snackbar(
        'Error',
        _error.value,
        backgroundColor: Colors.red.withOpacity(.1),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  String? validateNewPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return "Please enter a new Password";
    }
    if (value!.length < 6) {
      return "Password must be at least 6 characters";
    }
    if (value == currentPasswordController.text) {
      return "New password must be different from current password";
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return "Please confirm your new Password";
    }
    if (value != newPasswordController.text) {
      return "Password does n't match";
    }
    return null;
  }

  String? validateCurrentPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return "Please enter your new Password";
    }
    if (value!.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  void clearError() {
    _error.value = '';
  }
}
