import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'record_form_controller.dart';

/// 이력 추가 — DI 등록.
class MeProfileRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeProfileRecordController>(
      () => MeProfileRecordController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
