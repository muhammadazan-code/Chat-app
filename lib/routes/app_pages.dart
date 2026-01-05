import 'package:chat_app/controllers/main_controller.dart';
import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/views/auth/forgot_password_view.dart';
import 'package:chat_app/views/auth/login_view.dart';
import 'package:chat_app/views/auth/main_view.dart';
import 'package:chat_app/views/auth/profile/change_password_view.dart';
import 'package:chat_app/views/auth/profile/profile_view.dart';
import 'package:chat_app/views/auth/register_view.dart';
import 'package:chat_app/views/auth/splash_view.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/get_navigation.dart';

class AppPages {
  static const initial = AppRoutes.splashView;
  static final routes = [
    GetPage(name: AppRoutes.splashView, page: () => const SplashView()),
    GetPage(name: AppRoutes.loginView, page: () => const LoginView()),
    GetPage(name: AppRoutes.registerView, page: () => const RegisterView()),
    // GetPage(
    //   name: AppRoutes.home,
    //   page: () => const HomeView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(HomeController());
    //   }),
    // ),
    GetPage(
      name: AppRoutes.mainView,
      page: () => MainView(),
      binding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    ),
    GetPage(
      name: AppRoutes.forgotPasswordView,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: AppRoutes.changePasswordView,
      page: () => const ChangePasswordView(),
    ),
    GetPage(
      name: AppRoutes.profileView,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    // GetPage(
    //   name: AppRoutes.usersList,
    //   page: () => const UserListView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(UserListController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.friendRequest,
    //   page: () => const FriendsRequestView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(FriendRequestController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.friends,
    //   page: () => const FriendsView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(FriendController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.notifications,
    //   page: () => const NotificationsView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(NotificationController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.chat,
    //   page: () => const ChatView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(ChatController());
    //   }),
    // ),
  ];
}
