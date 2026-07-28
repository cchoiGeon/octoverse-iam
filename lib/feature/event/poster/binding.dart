import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'event_poster_controller.dart';

/// 홍보포스터 — DI 등록.
class EventPosterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventPosterController>(
      () => EventPosterController(
        Get.find<ApiClient>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
