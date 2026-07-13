import 'package:get/get.dart';
import 'package:vibe_chat/features/search_user/presentation/controller/search_user_controller.dart';

class SearchUserBinding extends Bindings {
  @override
  void dependencies() {
   Get.lazyPut(()=>SearchUserController());

  }
}