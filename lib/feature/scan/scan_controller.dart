import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/services.dart';

/// J1·J2 QR 스캐너 — 모임 참가 전용.
///
/// 라우트   : AppRoutes.scan
/// 웹 대응  : `IAM_web/src/app/(app)/scan/page.tsx`
///
/// ⚠️ 체크인에는 쓰지 않는다(체크인 = 6자리 코드 입력).
/// 앱에 존재하는 QR은 "참가 QR" 하나뿐이다.
class ScanController extends GetxController {
  ScanController(this._toast);

  final ToastService _toast;

  /// 카메라를 못 쓰는 이유. null이면 정상.
  final RxnString unavailable = RxnString();

  /// 같은 QR로 콜백이 반복돼도 한 번만 처리한다.
  bool _handled = false;
  DateTime? _lastForeignToast;

  /// 참가 QR = `{origin}/event/{slug}`. 이 형식만 우리 것으로 인정한다.
  String? slugFrom(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final i = segments.indexOf('event');
    if (i < 0 || i + 1 >= segments.length) return null;
    // 호스트까지 확인하면 스테이징 QR을 못 읽는다 — 경로 형식만 본다.
    return segments[i + 1];
  }

  void onDetect(String raw) {
    if (_handled) return;
    final slug = slugFrom(raw);
    if (slug == null) {
      _onForeign();
      return;
    }
    _handled = true;
    // 참가 실행은 상세의 "참가 신청" CTA가 맡는다 — 여기서는 이동만.
    Get.offNamed(AppRoutes.eventDetailOf(slug));
  }

  /// 엉뚱한 QR이 계속 잡혀도 토스트가 연타되지 않게 쿨다운을 둔다.
  void _onForeign() {
    final now = DateTime.now();
    if (_lastForeignToast != null &&
        now.difference(_lastForeignToast!) < const Duration(seconds: 3)) {
      return;
    }
    _lastForeignToast = now;
    _toast.error('IAM 모임 참가 QR이 아니에요');
  }

  void onUnavailable(String reason) => unavailable.value = reason;

  void goHome() => Get.offAllNamed(AppRoutes.home);

  /// 스캔이 막혔을 때의 대안 — 이름으로 찾기.
  void goSearch() => Get.offAllNamed(AppRoutes.home);

  String get webOrigin => kWebOrigin;
}
