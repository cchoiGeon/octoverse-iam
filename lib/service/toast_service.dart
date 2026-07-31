import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/core/network/api_error.dart';

enum ToastTone { neutral, success, error, info }

/// 전역 토스트 — `IAM_web/src/lib/services/toast.tsx` 이식.
///
/// 웹은 Context + 고정 컨테이너였지만 여기서는 GetX 스낵바를 감싼다.
/// 화면 어디서든 `Get.find<ToastService>().error(...)`로 부른다.
class ToastService extends GetxService {
  static const _duration = Duration(milliseconds: 3200);

  void show(String message, {ToastTone tone = ToastTone.neutral}) {
    // 연타로 여러 개가 쌓이지 않게 열려 있으면 닫고 새로 띄운다.
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.rawSnackbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          color: _fg(tone),
          fontWeight: AppTypography.semibold,
        ),
      ),
      backgroundColor: _bg(tone),
      // 하단 고정 CTA 위로 띄운다(웹의 --bottom-cta-h 여유와 같은 의도).
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.gutterMobile,
        vertical: AppDimens.space4,
      ),
      borderRadius: AppDimens.radiusMd,
      duration: _duration,
      animationDuration: AppMotion.base,
      snackPosition: SnackPosition.BOTTOM,
      isDismissible: true,
    );
  }

  void success(String message) => show(message, tone: ToastTone.success);
  void error(String message) => show(message, tone: ToastTone.error);
  void info(String message) => show(message, tone: ToastTone.info);

  /// 화면을 닫고 **나서** 성공 토스트를 띄운다.
  ///
  /// ⚠️ 순서가 계약의 일부다. GetX의 `Get.back()`은 스낵바가 떠 있으면
  /// **라우트 대신 스낵바만 닫고 그대로 반환한다**:
  ///
  /// ```dart
  /// // get 4.x · extension_navigation.dart
  /// if (isSnackbarOpen && !closeOverlays) {
  ///   closeCurrentSnackbar();
  ///   return;            // ← pop 하지 않는다
  /// }
  /// ```
  ///
  /// 그래서 `toast.success(...)` 뒤에 `Get.back()`을 부르면 저장은 됐는데
  /// 화면이 그대로 남아 "실패한 것처럼" 보이고, 호출부가 기다리던 결과값도
  /// 전달되지 않는다(목록이 갱신되지 않는다). 실제로 그렇게 한 번 당했다.
  ///
  /// `closeOverlays: true`로도 피할 수 있지만 그건 `popUntil`이라 다이얼로그·
  /// 바텀시트가 열려 있으면 여러 라우트를 한꺼번에 닫는다. 순서를 뒤집는 쪽이 안전하다.
  /// 토스트는 오버레이라 라우트가 바뀌어도 목적지 화면 위에 그대로 뜬다.
  void backThen(String message, {Object? result}) {
    Get.back<Object?>(result: result);
    success(message);
  }

  /// 예외를 한국어로 바꿔 띄운다. 화면은 서버 문구를 몰라도 된다.
  /// 웹의 `toast.showError(e)`에 대응한다.
  void showError(Object e) => error(ApiError.from(e).displayMessage);

  Color _bg(ToastTone tone) => switch (tone) {
    ToastTone.success => AppColors.success700,
    ToastTone.error => AppColors.error600,
    ToastTone.info => AppColors.info600,
    ToastTone.neutral => AppColors.gray800,
  };

  Color _fg(ToastTone tone) => switch (tone) {
    _ => AppColors.gray0,
  };
}
