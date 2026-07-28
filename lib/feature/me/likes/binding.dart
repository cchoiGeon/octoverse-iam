import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';

import 'me_likes_controller.dart';

/// 12 찜 관리 — DI 등록.
class MeLikesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeLikesController>(
      () => MeLikesController(Get.find<ApiClient>()),
    );
  }
}
