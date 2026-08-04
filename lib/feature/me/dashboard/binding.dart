import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'me_dashboard_controller.dart';

/// 09 마이 대시보드 — DI 등록.
class MeDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeDashboardController>(
      () => MeDashboardController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<NotificationService>(),
      ),
    );
  }
}
