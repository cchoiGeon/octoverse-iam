// Flutter 의 `Page`(navigator)가 우리 `Page<T>` DTO와 이름이 겹친다.
import 'package:flutter/widgets.dart' hide Page;
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 07 참가자 리스트.
///
/// 라우트   : AppRoutes.eventPeople (`/event/:slug/people`)
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/people/page.tsx`
///
/// 검색·정렬은 **전부 클라이언트**다 — swagger상 participations의 허용 쿼리는
/// page/size/status 뿐이고, sort를 넘기면 400(VALIDATION_ERROR)이 난다.
class EventPeopleController extends GetxController {
  EventPeopleController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  late final String slug = Get.parameters['slug'] ?? '';

  final RxList<ParticipationRow> rows = <ParticipationRow>[].obs;
  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();
  final RxSet<String> likedIds = <String>{}.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// 참가 확정 전이라 목록을 볼 수 없는 상태(403).
  final RxBool accessDenied = false.obs;

  final searchController = TextEditingController();
  final RxString search = ''.obs;
  final RxString sort = 'join_at'.obs;

  /// 사용자가 직접 정렬을 고른 적 있는지. 있으면 기본값 자동 전환을 하지 않는다.
  final RxBool sortTouched = false.obs;

  String? get myId => _auth.myId;
  bool get isOrganizer =>
      channel.value != null && _auth.isOrganizer(channel.value!.organizer.id);

  Organizer? get organizer => channel.value?.organizer;

  /// 참석자가 한 명이라도 있으면 "참석한 사람 먼저" 정렬을 선택지에 넣는다.
  bool get hasAttendance => rows.any((r) => r.attended);

  /// 체크인 창이 열린 뒤에는 기본 정렬을 참석 먼저로 바꾼다.
  /// 단 사용자가 직접 고른 적이 있으면 그 선택을 존중한다.
  String get effectiveSort {
    final requested = sortTouched.value
        ? sort.value
        : (hasAttendance ? 'checked_in' : 'join_at');
    // 참석자가 없는데 참석 정렬이 남아 있으면 선택지에 없는 값이 된다.
    return requested == 'checked_in' && !hasAttendance ? 'join_at' : requested;
  }

  int get acceptedTotal => rows.length;
  int get attendedCount => rows.where((r) => r.attended).length;

  /// 채널 멤버 = accepted 참가자 + 주최자.
  /// 주최자는 participations에 없지만 찜 대상/주체가 될 수 있다.
  Set<String> get _memberIds => {
    ...rows.map((r) => r.user.id),
    if (organizer != null) organizer!.id,
  };

  /// 내가 멤버가 아니면 찜 버튼을 아예 그리지 않는다(상세의 판정과 일치).
  bool get meIsMember => myId != null && _memberIds.contains(myId);

  bool get hasFilter => search.value.trim().isNotEmpty;

  /// 검색·정렬을 적용한 목록.
  List<ParticipationRow> get visible {
    final q = search.value.trim().toLowerCase();
    final matched = rows.where((r) {
      if (q.isEmpty) return true;
      return (r.user.nickname ?? '').toLowerCase().contains(q);
    }).toList();

    switch (effectiveSort) {
      case 'nickname':
        matched.sort(
          (a, b) => (a.user.nickname ?? '').compareTo(b.user.nickname ?? ''),
        );
      case 'checked_in':
        // 현장에서 목록을 여는 이유는 "지금 여기 누가 있나"이기 때문.
        // sort는 stable 이라 그룹 안에서는 가입순이 유지된다.
        matched.sort(
          (a, b) => (b.attended ? 1 : 0).compareTo(a.attended ? 1 : 0),
        );
      default:
        break; // join_at = 서버 기본 순서
    }
    return matched;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    accessDenied.value = false;
    try {
      // 채널·참가자·내 찜을 한 번에. 찜 목록은 실패해도 화면을 막지 않는다.
      final results = await Future.wait([
        _api.channel(slug),
        _api.participants(slug, status: 'accepted', size: 100),
      ]);
      channel.value = results[0] as ChannelDetail;
      rows.value = (results[1] as Page<ParticipationRow>).content;

      try {
        final likes = await _api.channelSentLikes(slug);
        likedIds.assignAll(likes.content.map((r) => r.user.id));
      } catch (_) {
        likedIds.clear();
      }
    } catch (e) {
      final err = ApiError.from(e);
      accessDenied.value = err.code == 'NOT_ORGANIZER' || err.isForbidden;
      error.value = err.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String v) => search.value = v;

  void onSearchCleared() {
    searchController.clear();
    search.value = '';
  }

  void onSortChanged(String v) {
    sortTouched.value = true;
    sort.value = v;
  }

  /// 찜 토글 — 낙관적으로 먼저 반영하고 실패하면 되돌린다.
  /// (되돌릴 수 있는 액션이라 체크인과 달리 낙관적 갱신을 쓴다.)
  Future<void> toggleLike(String userId, bool next) async {
    final had = likedIds.contains(userId);
    if (next) {
      likedIds.add(userId);
    } else {
      likedIds.remove(userId);
    }
    try {
      if (next) {
        await _api.like(slug, {'to_user_id': userId});
      } else {
        await _api.unlike(slug, userId);
      }
    } catch (e) {
      if (had) {
        likedIds.add(userId);
      } else {
        likedIds.remove(userId);
      }
      _toast.showError(e);
    }
  }

  /// 본인이거나 내가 멤버가 아니면 찜 버튼을 숨긴다.
  bool canLike(String userId) => myId != userId && meIsMember;

  void openProfile(String userId) =>
      Get.toNamed(AppRoutes.eventPeopleDetailOf(slug, userId));
}
