import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 14 설정.
///
/// 라우트   : AppRoutes.meSettings
/// 웹 대응  : `IAM_web/src/app/(app)/me/settings/page.tsx`
class MeSettingsController extends GetxController {
  MeSettingsController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final RxBool isLoading = true.obs;
  final RxBool emailEnabled = false.obs;
  final RxBool isBusy = false.obs;

  String get email => _auth.me.value?.email ?? '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final s = await _api.settings();
      emailEnabled.value = s.emailNotificationEnabled;
    } catch (_) {
      // 설정을 못 읽어도 화면은 뜬다 — 토글은 현재값(false)에서 시작.
    } finally {
      isLoading.value = false;
    }
  }

  /// 토글은 즉시 반영하고 실패하면 되돌린다.
  Future<void> setEmailEnabled(bool next) async {
    final prev = emailEnabled.value;
    emailEnabled.value = next;
    try {
      await _api.updateSettings(
        SettingsUpdateRequest(emailNotificationEnabled: next),
      );
    } catch (e) {
      emailEnabled.value = prev;
      _toast.showError(e);
    }
  }

  Future<void> logout() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _auth.logout();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isBusy.value = false;
    }
  }

  /// 진행 중인 주최 모임이 있으면 서버가 `ACTIVE_ORGANIZER`로 거절한다.
  Future<void> withdraw() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _auth.withdraw();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> openTerms() => _open(kTermsUrl);
  Future<void> openPrivacy() => _open(kPrivacyUrl);

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast.error('페이지를 열 수 없어요.');
    }
  }
}
