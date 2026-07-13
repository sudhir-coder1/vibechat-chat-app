import 'package:get/get.dart';
import 'package:vibe_chat/features/auth/login/binding/login_binding.dart';
import 'package:vibe_chat/features/auth/user_name/binding/user_name_binding.dart';
import 'package:vibe_chat/features/auth/user_name/presentation/screens/user_name.dart';
import 'package:vibe_chat/features/chat/binding/chat_binding.dart';
import 'package:vibe_chat/features/dashboard/binding/dashboard_binding.dart';
import 'package:vibe_chat/features/forget_password/binding/forget_password_binding.dart';
import 'package:vibe_chat/features/forget_password/presentation/screens/forget_password.dart';
import 'package:vibe_chat/features/home/binding/home_binding.dart';
import 'package:vibe_chat/features/profile/binding/profile_bonding.dart';
import 'package:vibe_chat/features/search_user/binding/search_user_binding.dart';
import 'package:vibe_chat/features/search_user/presentation/screens/search_user.dart';
import 'package:vibe_chat/features/splash/presentation/screens/splash_page.dart';
import 'package:vibe_chat/features/requests/binding/requests_binding.dart';
import 'package:vibe_chat/features/requests/presentation/screens/requests_page.dart';

import '../../features/auth/login/presentation/screens/login_pge.dart';
import '../../features/chat/presentation/screens/chat_page.dart';
import '../../features/dashboard/presentation/screens/dashboard_page.dart';
import '../../features/home/presentation/screens/home_page.dart';
import '../../features/splash/binding/splash_binding.dart';

class AppRoute {
  static const dashboard = "/dashboardPage";
  static const login = "/login";
  static const splash = "/";
  static const home = "/home";
  static const chat = "/chatScreen";
  static const username = "/username";
  static const searchUser = "/search";
  static const forgetPassword = "/forget";
  static const requests = "/requests";

  static List<GetPage> page = [
    GetPage(
      name: dashboard,
      page: () => DashboardPage(),
      bindings: [
        DashboardBinding(),
        HomeBinding(),
        ProfileBinding(),
        LoginBinding(),
        ChatBinding(),
        SearchUserBinding(),
      ],
    ),
    GetPage(
      name: home,
      page: () => HomePage(),
      binding: HomeBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: splash,
      page: () => SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: login,
      page: () => LoginPage(),
      binding: LoginBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: chat,
      page: () => ChatPage(),
      binding: ChatBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: username,
      page: () => UserName(),
      binding: UserNameBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: searchUser,
      page: () => SearchUser(),
      binding: SearchUserBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: forgetPassword,
      page: () => ForgetPassword(),
      binding: ForgetPasswordBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoute.requests,
      page: () => const RequestsPage(),
      binding: RequestsBinding(),
      transition: Transition.fade,
    ),
  ];
}
