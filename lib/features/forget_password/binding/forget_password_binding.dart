import 'package:get/instance_manager.dart';
import 'package:vibe_chat/features/forget_password/presentation/controller/forget_password_controller.dart';

class ForgetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>ForgetPasswordController());
  }
}