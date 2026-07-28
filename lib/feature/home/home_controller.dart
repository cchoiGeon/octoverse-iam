import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/utils/channel_utils.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 04b 모임 둘러보기 — 검색 · 무한 스크롤.
///
/// 라우트   : AppRoutes.home
/// 웹 대응  : `IAM_web/src/app/(app)/page.tsx`의 `<Explore>`
///
/// **웹과의 구조 차이**: 웹은 `useInfiniteQuery`가 페이지 누적·캐시를 맡았다.
/// 여기서는 이 컨트롤러가 `_page`·`_hasNext`를 직접 들고 관리한다.
class HomeController extends GetxController {
  HomeController(this._api, this._reference, this._notifications, this._toast);

  final ApiClient _api;
  final ReferenceService _reference;
  final NotificationService _notifications;
  final ToastService _toast;

  final RxList<ChannelListItem> channels = <ChannelListItem>[].obs;

  /// 첫 로드(스켈레톤 대상).
  final RxBool isLoading = true.obs;

  /// 다음 페이지 로드(하단 스피너).
  final RxBool isLoadingMore = false.obs;

  final RxnString error = RxnString();

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  /// 헤더 벨 배지.
  int get unreadCount => _notifications.unreadCount;

  int _page = 0;
  bool _hasNext = true;
  String _query = '';
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    load();
    // 알림은 보조 정보라 실패해도 화면을 막지 않는다.
    _notifications.load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// 검색어 입력 — 400ms 디바운스 후 서버 재조회.
  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      load();
    });
  }

  void onSearchCleared() {
    _debounce?.cancel();
    _query = '';
    load();
  }

  /// 첫 페이지부터 다시 불러온다. 당겨서 새로고침·재시도도 이 경로.
  Future<void> load() async {
    _page = 0;
    _hasNext = true;
    error.value = null;
    isLoading.value = true;
    try {
      final page = await _api.channels(
        q: _query.isEmpty ? null : _query,
        category: category.value,
        interest: interest.value,
        sort: _serverSort,
        page: 0,
        size: kPageSize,
      );
      channels.value = page.content;
      _hasNext = page.hasNext;
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
      channels.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasNext || isLoading.value) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final page = await _api.channels(
        q: _query.isEmpty ? null : _query,
        category: category.value,
        interest: interest.value,
        sort: _serverSort,
        page: next,
        size: kPageSize,
      );
      channels.addAll(page.content);
      _page = next;
      _hasNext = page.hasNext;
    } catch (e) {
      // 다음 페이지 실패는 목록 전체를 날리지 않는다 — 토스트로만 알린다.
      _toast.showError(e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    // 바닥 200px 전에 미리 당겨온다(웹 IntersectionObserver rootMargin과 같은 의도).
    if (pos.pixels >= pos.maxScrollExtent - 200) loadMore();
  }

  /// 관심사 태그 id/이름 → 한국어 라벨.
  String interestLabel(InterestTag tag) => tag.label;

  // ══════════════════════════════════════════════════════════
  // 필터 · 정렬
  // ══════════════════════════════════════════════════════════

  /// 서버가 지원하는 sort는 start_at / created_at 뿐이다.
  /// 인기순·가나다순은 불러온 목록 안에서 클라이언트가 정렬한다.
  static const sortCreatedAt = 'created_at';
  static const sortStartAt = 'start_at';
  static const sortPopular = 'accepted_count';
  static const sortName = 'name';

  static const clientSorts = {sortPopular, sortName};

  final RxString sort = sortCreatedAt.obs;
  final RxnString category = RxnString();
  final RxnString interest = RxnString();

  /// 시간 기반 phase 필터. 서버는 "진행 중"을 표현할 수 없어 클라이언트가 거른다.
  final RxnString statusFilter = RxnString();

  bool get sortChanged => sort.value != sortCreatedAt;

  int get filterCount => [
    category.value,
    interest.value,
    statusFilter.value,
  ].where((v) => v != null).length;

  ReferenceService get reference => _reference;

  /// 서버에 넘길 sort — 클라 전용 정렬이면 안전한 created_at 으로 요청한다.
  String get _serverSort =>
      clientSorts.contains(sort.value) ? sortCreatedAt : sort.value;

  /// 상태 필터 + 클라이언트 정렬을 적용한 목록.
  List<ChannelListItem> get visible {
    var list = channels.toList();

    final want = statusFilter.value;
    if (want != null) {
      list = list.where((c) {
        final p = ChannelUtils.phaseOfListItem(c);
        return switch (want) {
          // "모집중"은 아직 신청을 받는 상태 — 정원 마감은 제외한다.
          'open' => p == ChannelPhase.open || p == ChannelPhase.soon,
          'live' => p == ChannelPhase.live,
          'past' => p == ChannelPhase.past,
          _ => true,
        };
      }).toList();
    }

    if (sort.value == sortPopular) {
      list.sort((a, b) => b.acceptedCount.compareTo(a.acceptedCount));
    } else if (sort.value == sortName) {
      list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  void applyFilter({String? category, String? interest, String? status}) {
    this.category.value = category;
    this.interest.value = interest;
    statusFilter.value = status;
    load();
  }

  void setSort(String value) {
    sort.value = value;
    // 클라 정렬은 재조회가 필요 없다 — 불러온 목록만 다시 세운다.
    if (!clientSorts.contains(value)) load();
  }

  void resetFilters() {
    category.value = null;
    interest.value = null;
    statusFilter.value = null;
    searchController.clear();
    _query = '';
    load();
  }
}
