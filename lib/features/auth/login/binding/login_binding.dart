import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:vibe_chat/features/auth/login/presentation/controller/login_controller.dart';

class LoginBinding extends Bindings {
  @override

  void dependencies() {
Get.lazyPut(()=>LoginController());
  }
}