import 'package:chat_app/controllers/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  


}
