import 'package:get/get.dart';
import 'package:vibe_chat/features/dashboard/presentation/controller/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>DashboardController());
  }
}