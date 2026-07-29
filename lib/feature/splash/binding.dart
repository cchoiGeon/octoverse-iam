import 'package:get/get.dart';

import 'package:iam/service/services.dart';

import 'splash_controller.dart';

/// 부팅 · 세션 확인 — DI 등록.
///
/// ⚠️ **`lazyPut`이 아니라 `put`이다.** 스플래시 화면은 정적이라 뷰가
/// `controller`를 한 번도 참조하지 않는다. lazy로 두면 컨트롤러가 생성되지
/// 않아 `onReady()`가 영영 실행되지 않고, 앱이 스플래시에서 멈춘다.
/// 뷰가 읽지 않아도 반드시 살아야 하는 컨트롤러는 eager로 등록한다.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(
        Get.find<AuthService>(),
        Get.find<ReferenceService>(),
        Get.find<PushService>(),
      ),
    );
  }
}
