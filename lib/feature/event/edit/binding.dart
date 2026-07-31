import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_edit_controller.dart';

/// 06b 모임 수정 — DI 등록.
class EventEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventEditController>(
      () => EventEditController(
        Get.find<ApiClient>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
        Get.find<AuthService>(),
      ),
    );
  }
}
