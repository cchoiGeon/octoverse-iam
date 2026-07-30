import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'onboarding_controller.dart';

/// 02·03 프로필 작성 3스텝 — DI 등록.
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
        Get.find<PushService>(),
      ),
    );
  }
}
