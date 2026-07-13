import 'package:get/get.dart';
import '../presentation/controller/requests_controller.dart';

class RequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RequestsController>(() => RequestsController());
  }
}
