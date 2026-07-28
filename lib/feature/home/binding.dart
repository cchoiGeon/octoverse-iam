import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'home_controller.dart';

/// 04b 모임 둘러보기 — DI 등록.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<ApiClient>(),
        Get.find<ReferenceService>(),
        Get.find<NotificationService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
