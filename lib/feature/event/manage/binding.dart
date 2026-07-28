import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_manage_controller.dart';

/// 11b 참가자 관리 — DI 등록.
class EventManageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventManageController>(
      () => EventManageController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
