import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'career_form_controller.dart';

/// 경력 추가 — DI 등록.
class MeProfileCareerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeProfileCareerController>(
      () => MeProfileCareerController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
