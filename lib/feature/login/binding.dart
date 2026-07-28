import 'package:get/get.dart';

import 'package:iam/service/services.dart';

import 'login_controller.dart';

/// 01 랜딩 · 카카오 로그인 — DI 등록.
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<AuthService>(), Get.find<ToastService>()),
    );
  }
}
