import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'link_form_controller.dart';

/// 외부 링크 추가 — DI 등록.
class MeProfileLinkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeProfileLinkController>(
      () => MeProfileLinkController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
