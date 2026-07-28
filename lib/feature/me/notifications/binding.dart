import 'package:get/get.dart';

import 'package:iam/service/services.dart';

import 'me_notifications_controller.dart';

/// 13 알림 센터 — DI 등록.
class MeNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeNotificationsController>(
      () => MeNotificationsController(Get.find<NotificationService>()),
    );
  }
}
