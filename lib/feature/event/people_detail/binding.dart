import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_people_detail_controller.dart';

/// 08 프로필 상세 — DI 등록.
class EventPeopleDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventPeopleDetailController>(
      () => EventPeopleDetailController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
