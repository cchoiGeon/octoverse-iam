import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_checkin_host_controller.dart';

/// S1 주최자 체크인 — DI 등록.
class EventCheckinHostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventCheckinHostController>(
      () => EventCheckinHostController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
      ),
    );
  }
}
