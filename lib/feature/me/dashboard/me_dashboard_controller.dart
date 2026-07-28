import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 09 마이 대시보드.
///
/// 라우트   : AppRoutes.me
/// 웹 대응  : `IAM_web/src/app/(app)/me/page.tsx`
class MeDashboardController extends GetxController {
  MeDashboardController(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  final RxBool isLoading = true.obs;

  final RxInt organizedCount = 0.obs;
  final RxInt joinedCount = 0.obs;
  final RxInt pendingCount = 0.obs;
  final RxInt likesCount = 0.obs;

  /// 명함첩 진입점 뱃지 — 받은 교환 요청(대기중) 수.
  final RxInt cardRequestCount = 0.obs;

  Me? get me => _auth.me.value;
  Profile? get profile => me?.profile;

  String get nickname => profile?.nickname ?? me?.email ?? '';
  String? get photoUrl => profile?.photoUrl;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    // 카운트는 다섯 군데서 오는데 하나가 실패해도 화면은 떠야 한다.
    // 각각 독립적으로 채우고 실패는 0으로 둔다.
    await Future.wait([
      _auth.refreshMe(),
      _count(
        () async => (await _api.myOrganizedChannels()).totalElements,
        organizedCount,
      ),
      _count(
        () async => (await _api.myJoinedChannels(
          participationStatus: 'accepted',
        )).totalElements,
        joinedCount,
      ),
      _count(
        () async => (await _api.myParticipations()).totalElements,
        pendingCount,
      ),
      _count(
        () async => (await _api.myLikes(direction: 'sent')).totalElements,
        likesCount,
      ),
      _count(
        () async => (await _api.myCardExchanges(
          direction: 'received',
          status: 'pending',
        )).totalElements,
        cardRequestCount,
      ),
    ]);
    isLoading.value = false;
  }

  Future<void> _count(Future<int> Function() fetch, RxInt target) async {
    try {
      target.value = await fetch();
    } catch (_) {
      target.value = 0;
    }
  }

  // ── 이동 ────────────────────────────────────────────────────
  void openProfile() => Get.toNamed(AppRoutes.meProfile);
  void openMeetings(String tab) =>
      Get.toNamed(AppRoutes.meMeetings, arguments: tab);
  void openLikes() => Get.toNamed(AppRoutes.meLikes);
  void openCards() => Get.toNamed(AppRoutes.meCards);
  void openNotifications() => Get.toNamed(AppRoutes.meNotifications);
  void openSettings() => Get.toNamed(AppRoutes.meSettings);
  void openCreateEvent() => Get.toNamed(AppRoutes.eventNew);
}
