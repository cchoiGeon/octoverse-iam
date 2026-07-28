import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'me_meetings_controller.dart';

/// 11 내 모임 — DI 등록.
class MeMeetingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeMeetingsController>(
      () =>
          MeMeetingsController(Get.find<ApiClient>(), Get.find<ToastService>()),
    );
  }
}
