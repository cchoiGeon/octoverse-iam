import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/service/services.dart';

import 'me_cards_edit_controller.dart';

/// 내 명함 등록·수정 — DI 등록.
class MeCardsEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeCardsEditController>(
      () => MeCardsEditController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
