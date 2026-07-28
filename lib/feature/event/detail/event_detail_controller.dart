import 'package:get/get.dart';

import 'package:iam/common/utils/channel_utils.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 05 모임 상세.
///
/// 라우트   : AppRoutes.eventDetail (`/event/:slug`)
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/page.tsx`
class EventDetailController extends GetxController {
  EventDetailController(this._api, this._auth, this._reference, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ReferenceService _reference;
  final ToastService _toast;

  late final String slug = Get.parameters['slug'] ?? '';

  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool isMutating = false.obs;

  /// 모임을 못 찾은 경우 — 삭제됐거나 잘못된 링크.
  final RxBool notFound = false.obs;

  bool get isOrganizer =>
      channel.value != null && _auth.isOrganizer(channel.value!.organizer.id);

  /// 시각·정원으로 계산한 상태. 서버 status가 아니다.
  ChannelPhase get phase => channel.value == null
      ? ChannelPhase.open
      : ChannelUtils.phaseOfDetail(channel.value!);

  ChannelCta get cta => channel.value == null
      ? ChannelCta.guest
      : ChannelUtils.ctaOf(
          channel.value!,
          isOrganizer: isOrganizer,
          isAuthenticated: _auth.isAuthenticated,
        );

  /// 체크인 창(start-1h ~ end)이 열렸는지. 진입점 노출용 — 판정 권한은 서버.
  CheckinWindowInfo get checkinWindow => channel.value == null
      ? const CheckinWindowInfo(opensAt: null, closesAt: null, isOpen: false)
      : ChannelUtils.checkinWindow(
          channel.value!.startAt,
          channel.value!.endAt,
        );

  /// 주최자·참가자에게만 체크인 진입점을 준다.
  bool get showCheckinFab =>
      checkinWindow.isOpen &&
      (cta == ChannelCta.organizer || cta == ChannelCta.joined);

  /// 미참가자에겐 FAB 대신 안내만 — 워크인은 제공하지 않는다.
  bool get showCheckinHint => checkinWindow.isOpen && cta == ChannelCta.join;

  /// 진행 중·지난 모임에서는 "참가 취소"를 숨긴다.
  /// 체크인하러 연 화면 옆에 취소 버튼이 있는 건 위험하다.
  bool get hideLeave =>
      phase == ChannelPhase.live || phase == ChannelPhase.past;

  String categoryLabel(EventCategory c) => _reference.categoryLabel(c);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (slug.isEmpty) {
      error.value = '잘못된 링크예요.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    error.value = null;
    notFound.value = false;
    try {
      channel.value = await _api.channel(slug);
    } catch (e) {
      final err = ApiError.from(e);
      notFound.value = err.code == 'CHANNEL_NOT_FOUND' || err.isNotFound;
      error.value = err.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> join() async {
    if (isMutating.value) return;
    isMutating.value = true;
    try {
      await _api.joinChannel(slug);
      _toast.success('참가 신청이 완료됐어요.');
      await load();
    } catch (e) {
      _toast.showError(e);
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> leave() async {
    if (isMutating.value) return;
    isMutating.value = true;
    try {
      await _api.leaveChannel(slug);
      _toast.success('참가를 취소했어요.');
      await load();
    } catch (e) {
      _toast.showError(e);
    } finally {
      isMutating.value = false;
    }
  }

  // ── 이동 ────────────────────────────────────────────────────
  void openPeople() => Get.toNamed(AppRoutes.eventPeopleOf(slug));
  void openManage() => Get.toNamed(AppRoutes.eventManageOf(slug));
  void openEdit() => Get.toNamed(AppRoutes.eventEditOf(slug));
  void openCheckin() => Get.toNamed(
    isOrganizer
        ? AppRoutes.eventCheckinHostOf(slug)
        : AppRoutes.eventCheckinOf(slug),
  );
  void goLanding() => Get.offAllNamed(AppRoutes.login);
}
