// Flutter 의 `Page`(navigator)가 우리 `Page<T>` DTO와 이름이 겹친다.
import 'package:flutter/widgets.dart' hide Page;
import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 체크인이 끝난 이유 — 재시도해도 소용없는 상태들.
enum CheckinTerminal { notOpen, closed, notParticipating, ownChannel }

/// S2~S4 참가자 체크인.
///
/// 라우트   : AppRoutes.eventCheckin
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/checkin/page.tsx`
///
/// **코드 입력이 유일한 경로다** — QR·카메라는 쓰지 않는다.
/// ⚠️ **낙관적 UI 금지.** v1엔 정정 경로가 없어 서버 200 전에 성공을 보이면
///    안 된다(찜과 다르게 되돌릴 수 없다).
class EventCheckinController extends GetxController {
  EventCheckinController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  late final String slug = Get.parameters['slug'] ?? '';

  final code = TextEditingController();
  final codeFocus = FocusNode();

  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();
  final Rxn<CheckInResult> result = Rxn<CheckInResult>();
  final Rxn<CheckinTerminal> terminal = Rxn<CheckinTerminal>();

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString inlineError = RxnString();

  /// 성공 화면에서만 쓰는 조합 — 찜(sent) ∩ 참석. 서버 추가 작업 0.
  final RxInt likedAttending = 0.obs;

  @override
  void onInit() {
    super.onInit();
    code.addListener(_onCodeChanged);
    load();
  }

  @override
  void onClose() {
    code.removeListener(_onCodeChanged);
    code.dispose();
    codeFocus.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      channel.value = await _api.channel(slug);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 6자리를 다 채우면 자동 제출한다 — 버튼을 한 번 더 누르게 하지 않는다.
  void _onCodeChanged() {
    if (code.text.length == kCheckinCodeLength) submit();
  }

  Future<void> submit() async {
    if (code.text.length != kCheckinCodeLength || isSubmitting.value) return;
    isSubmitting.value = true;
    inlineError.value = null;
    try {
      result.value = await _api.submitCheckIn(slug, {'code': code.text});
      await _loadLikedAttending();
    } catch (e) {
      _handleError(ApiError.from(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 실패는 두 갈래다 — 다시 시도할 수 있는 것(인라인)과 끝난 것(전용 화면).
  void _handleError(ApiError err) {
    switch (err.code) {
      case 'CHECKIN_CODE_INVALID':
        inlineError.value = '체크인 코드가 올바르지 않아요. 다시 확인해주세요.';
        _clearCode();
      case 'TOO_MANY_ATTEMPTS':
        inlineError.value = '시도가 너무 많아요. 잠시 후 다시 시도해주세요.';
        _clearCode();
      case 'CHECKIN_NOT_OPEN':
        terminal.value = CheckinTerminal.notOpen;
      case 'CHECKIN_CLOSED':
        terminal.value = CheckinTerminal.closed;
      case 'NOT_PARTICIPATING':
        terminal.value = CheckinTerminal.notParticipating;
      case 'CANNOT_CHECKIN_OWN_CHANNEL':
        terminal.value = CheckinTerminal.ownChannel;
      default:
        _toast.error(err.displayMessage);
        _clearCode();
    }
  }

  void _clearCode() {
    code.clear();
    codeFocus.requestFocus();
  }

  /// "찜한 N명이 참석해 있어요" — 누가 왔는지는 목록에서 보게 한다.
  Future<void> _loadLikedAttending() async {
    try {
      final results = await Future.wait([
        _api.channelSentLikes(slug),
        _api.participants(slug, status: 'accepted', size: 100),
      ]);
      final liked = (results[0] as Page<LikeRow>).content
          .map((r) => r.user.id)
          .toSet();
      likedAttending.value = (results[1] as Page<ParticipationRow>).content
          .where((p) => p.attended && liked.contains(p.user.id))
          .length;
    } catch (_) {
      likedAttending.value = 0;
    }
  }

  /// 참가 신청 후 바로 코드 입력으로 돌아온다.
  Future<void> joinThenRetry() async {
    try {
      await _api.joinChannel(slug);
      _toast.success('참가 신청이 완료됐어요. 코드를 입력해주세요.');
      terminal.value = null;
      _clearCode();
    } catch (e) {
      _toast.showError(e);
    }
  }

  void goPeople() => Get.offNamed(AppRoutes.eventPeopleOf(slug));
  void goEvent() => Get.offNamed(AppRoutes.eventDetailOf(slug));
  void goHostCheckin() => Get.offNamed(AppRoutes.eventCheckinHostOf(slug));
}
