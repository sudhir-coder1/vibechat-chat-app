import 'package:get/get.dart';
import 'package:vibe_chat/features/auth/user_name/presentation/controller/user_name_controller.dart';

class UserNameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>UserNameController());
  }
}