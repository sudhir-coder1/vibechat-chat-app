import 'package:get/get.dart';
import 'package:vibe_chat/features/splash/presentation/controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>SplashController());
  }
}