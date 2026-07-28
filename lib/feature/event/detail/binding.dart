import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_detail_controller.dart';

/// 05 모임 상세 — DI 등록.
class EventDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventDetailController>(
      () => EventDetailController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
