import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'me_profile_controller.dart';

/// 10 내 프로필 편집 — DI 등록.
class MeProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeProfileController>(
      () => MeProfileController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
