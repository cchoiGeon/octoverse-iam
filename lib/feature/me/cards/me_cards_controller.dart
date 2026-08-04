import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 명함첩 — 교환 완료 · 받은 요청 · 보낸 요청.
///
/// 라우트   : AppRoutes.meCards
/// 웹 대응  : `IAM_web/src/app/(app)/me/cards/page.tsx`
class MeCardsController extends GetxController {
  MeCardsController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  static const tabs = ['명함첩', '받은 요청', '보낸 요청'];

  final RxInt tab = 0.obs;
  final Rxn<BusinessCard> myCard = Rxn<BusinessCard>();
  final RxList<CardExchangeListItem> accepted = <CardExchangeListItem>[].obs;
  final RxList<CardExchangeListItem> received = <CardExchangeListItem>[].obs;
  final RxList<CardExchangeListItem> sent = <CardExchangeListItem>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxnString busyId = RxnString();

  List<CardExchangeListItem> get current => switch (tab.value) {
    0 => accepted,
    1 => received,
    _ => sent,
  };

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      myCard.value = await _myCardOrNull();
      final all = await _api.myCardExchanges(size: 100);
      accepted.value = all.content
          .where((e) => e.status == CardExchangeStatus.accepted)
          .toList();
      received.value = all.content
          .where(
            (e) =>
                e.direction == ExchangeDirection.received &&
                e.status == CardExchangeStatus.pending,
          )
          .toList();
      sent.value = all.content
          .where(
            (e) =>
                e.direction == ExchangeDirection.sent &&
                e.status == CardExchangeStatus.pending,
          )
          .toList();
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// 미등록(404)은 오류가 아니라 null이다.
  Future<BusinessCard?> _myCardOrNull() async {
    try {
      return await _api.myBusinessCard();
    } catch (e) {
      if (ApiError.from(e).isNotFound) return null;
      rethrow;
    }
  }

  Future<void> accept(CardExchangeListItem e) =>
      _act(e, () => _api.acceptCardExchange(e.id), '명함을 교환했어요.');

  Future<void> reject(CardExchangeListItem e) =>
      _act(e, () => _api.rejectCardExchange(e.id), '요청을 거절했어요.');

  Future<void> cancel(CardExchangeListItem e) =>
      _act(e, () => _api.cancelCardExchange(e.id), '요청을 취소했어요.');

  Future<void> _act(
    CardExchangeListItem e,
    Future<void> Function() action,
    String message,
  ) async {
    if (busyId.value != null) return;
    busyId.value = e.id;
    try {
      await action();
      _toast.success(message);
      await load();
    } catch (err) {
      _toast.showError(err);
    } finally {
      busyId.value = null;
    }
  }

  /// 편집 화면은 저장·삭제에 성공하면 `result: true` 로 닫힌다
  /// (`MeCardsEditController` → `ToastService.backThen`).
  ///
  /// 그 신호를 받아 다시 읽는다. 안 그러면 명함을 등록하고 돌아와도
  /// '내 명함'이 미등록 그대로 남는다. 결과가 없을 때(그냥 뒤로 나온 경우)는
  /// 재조회하지 않는다.
  Future<void> openEdit() async {
    final changed = await Get.toNamed<Object?>(AppRoutes.meCardsEdit);
    if (changed == true) await load();
  }
}
