import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'me_settings_controller.dart';

/// 14 설정 — DI 등록.
class MeSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeSettingsController>(
      () => MeSettingsController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
        Get.find<PushService>(),
      ),
    );
  }
}
