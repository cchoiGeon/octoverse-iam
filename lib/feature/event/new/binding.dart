import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_new_controller.dart';

/// 06 모임 생성 — DI 등록.
class EventNewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventNewController>(
      () => EventNewController(
        Get.find<ApiClient>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
