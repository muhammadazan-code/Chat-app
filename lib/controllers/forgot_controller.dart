import 'package:chat_app/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final AuthServices _authServices = AuthServices();
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final RxBool _isLoading = false.obs;
  final RxString _error = "".obs;
  final RxBool _emailSent = false.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get emailSent => _emailSent.value;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sentPasswordResetsEmail() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      await _authServices.sendPasswordsResetEmail(emailController.text.trim());

      _emailSent.value = true;
      Get.snackbar(
        'Success',
        'Password reset email sent to ${emailController.text.trim()}',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to sent link to ${emailController.text.trim()}',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void goBackToLogin() {
    Get.back();
  }

  void resetEmail() {
    _emailSent.value = false;
    sentPasswordResetsEmail();
  }

  String? validateEmail(String? value) {
    if (value!.isEmpty) {
      return "Please enter you email";
    }
    if (!GetUtils.isEmail(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  void _clearError() {
    _error.value = '';
  }
}
