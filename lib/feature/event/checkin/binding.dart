import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_checkin_controller.dart';

/// S2~S4 참가자 체크인 — DI 등록.
class EventCheckinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventCheckinController>(
      () => EventCheckinController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
