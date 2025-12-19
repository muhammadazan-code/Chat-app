import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirestoreServices _firestoreServices = FirestoreServices();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController displayName = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = "".obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadingUserData();
  }

  @override
  void onClose() {
    // displayName.dispose();
    // emailController.dispose();
    super.onClose();
  }

  void _loadingUserData() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _currentUser.bindStream(_firestoreServices.getUserStream(currentUserId));

      ever(_currentUser, (UserModel? user) {
        if (user != null) {
          displayName.text = user.displayName;
          emailController.text = user.email;
        }
      });
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayName.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final user = _currentUser.value;
      if (user == null) return;
      final updateUser = user.copyWith(displayName: displayName.text);

      await _firestoreServices.updateUser(updateUser);
      _isEditing.value = false;
      Get.snackbar('Success', "Profile updated successfully....");
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Update Profile');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authController.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Failed to Sign Out');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Delete Account"),
          content: Text(
            "Are you sure you want to delete your account? This action can not be undo.",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () => Get.back(result: true),
              child: Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        await _authController.deleteAccount();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to Delete Account');
    } finally {
      _isLoading.value = false;
    }
  }

  String getJoinedData() {
    final user = _currentUser.value;
    if (user == null) return '';
    final data = user.createdAt;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      "Nov",
      "Dec",
    ];

    return 'Joined ${months[data.month - 1]} ${data.year}';
  }

  void clearError() {
    _error.value = '';
  }
}
