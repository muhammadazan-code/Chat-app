import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _obsecurePassword = true;
  bool _obsecureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _confirmpasswordController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Fill in your details to get started",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    controller: _displayNameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter your name',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'Enter your email',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email.';
                      }
                      if (!GetUtils.isEmail(value!)) {
                        return 'Please enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obsecurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obsecurePassword = !_obsecurePassword;
                          });
                        },
                        icon: Icon(
                          _obsecurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your password.';
                      }
                      if (value!.length < 6) {
                        return "Password must be at least 6 characters.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmpasswordController,
                    obscureText: _obsecureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: 'Confirm your password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obsecureConfirmPassword =
                                !_obsecureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obsecureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please confirm your password";
                      }
                      if (value != _passwordController.text) {
                        return "Password do not match.";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _authController.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  _authController.registerWithEmailAndPassword(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    _displayNameController.text.trim(),
                                  );
                                }
                              },
                        child: _authController.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Create Account'),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.borderColor)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.borderColor)),
                    ],
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.loginView),
                        child: Text(
                          "Sign In",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
