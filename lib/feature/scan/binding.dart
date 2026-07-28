import 'package:get/get.dart';

import 'package:iam/service/services.dart';

import 'scan_controller.dart';

/// J1·J2 QR 스캐너 — DI 등록.
class ScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanController>(() => ScanController(Get.find<ToastService>()));
  }
}
