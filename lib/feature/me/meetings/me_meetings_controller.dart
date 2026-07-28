import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 11 내 모임 — 주최 · 참여 · 신청 대기.
///
/// 라우트   : AppRoutes.meMeetings
/// 웹 대응  : `IAM_web/src/app/(app)/me/meetings/page.tsx`
class MeMeetingsController extends GetxController {
  MeMeetingsController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  static const tabs = ['주최', '참여', '대기'];

  /// 대시보드 카운트 행에서 넘어올 때 탭을 지정한다.
  static const _tabByArgument = {'organized': 0, 'joined': 1, 'pending': 2};

  final RxInt tab = 0.obs;

  final RxList<ChannelListItem> organized = <ChannelListItem>[].obs;
  final RxList<JoinedChannelListItem> joined = <JoinedChannelListItem>[].obs;
  final RxList<MyParticipation> pending = <MyParticipation>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String && _tabByArgument.containsKey(arg)) {
      tab.value = _tabByArgument[arg]!;
    }
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _api.myOrganizedChannels(size: 50),
        _api.myJoinedChannels(participationStatus: 'accepted', size: 50),
        _api.myParticipations(),
      ]);
      organized.value = (results[0] as Page<ChannelListItem>).content;
      joined.value = (results[1] as Page<JoinedChannelListItem>).content;
      // 대기 탭은 pending 만 — 서버가 다른 상태도 섞어 줄 수 있다.
      pending.value = (results[2] as Page<MyParticipation>).content
          .where((p) => p.status == ParticipationStatus.pending)
          .toList();
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// 주최자 조기 종료. 되돌릴 수 없다.
  Future<void> closeChannel(String slug) async {
    try {
      await _api.closeChannel(slug);
      _toast.success('모임이 종료됐어요.');
      await load();
    } catch (e) {
      _toast.showError(e);
    }
  }

  Future<void> deleteChannel(String slug) async {
    try {
      await _api.deleteChannel(slug);
      _toast.success('모임이 삭제됐어요.');
      await load();
    } catch (e) {
      _toast.showError(e);
    }
  }

  void openDetail(String slug) => Get.toNamed(AppRoutes.eventDetailOf(slug));

  /// 아직 끝나지 않은 모임만 "관리"(승인/거절). 지난 모임은 명단 보기로.
  void openManageOrPeople(String slug, {required bool live}) => Get.toNamed(
    live ? AppRoutes.eventManageOf(slug) : AppRoutes.eventPeopleOf(slug),
  );

  void openEdit(String slug) => Get.toNamed(AppRoutes.eventEditOf(slug));
  void openCreate() => Get.toNamed(AppRoutes.eventNew);
}
