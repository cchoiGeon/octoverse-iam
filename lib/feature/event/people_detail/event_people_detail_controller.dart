import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 08 프로필 상세 — 찜 · 명함 교환.
///
/// 라우트   : AppRoutes.eventPeopleDetail (`/event/:slug/people/:userId`)
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/people/[userId]/page.tsx`
class EventPeopleDetailController extends GetxController {
  EventPeopleDetailController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  late final String slug = Get.parameters['slug'] ?? '';
  late final String userId = Get.parameters['userId'] ?? '';

  final Rxn<PublicUser> user = Rxn<PublicUser>();
  final Rxn<BusinessCard> myCard = Rxn<BusinessCard>();
  final Rxn<CardExchangeListItem> exchange = Rxn<CardExchangeListItem>();

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool notFound = false.obs;

  final RxBool liked = false.obs;
  final RxBool likePending = false.obs;
  final RxBool exchangePending = false.obs;

  /// 나와 상대가 모두 채널 멤버인지 — 찜 가능 조건.
  final RxBool bothMembers = false.obs;

  /// 교환 목록이 아직 안 왔는지. 확정 전에 "요청 가능"을 보이면 중복 요청이 나간다.
  final RxBool exchangeLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    notFound.value = false;
    try {
      user.value = await _api.user(userId);
      await Future.wait([_loadLikeState(), _loadExchangeState()]);
    } catch (e) {
      final err = ApiError.from(e);
      notFound.value = err.code == 'USER_NOT_FOUND' || err.isNotFound;
      error.value = err.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// 찜 상태 + 찜 자격(양쪽 다 멤버인지).
  Future<void> _loadLikeState() async {
    try {
      final results = await Future.wait([
        _api.channelSentLikes(slug),
        _api.participants(slug, status: 'accepted', size: 100),
        _api.channel(slug),
      ]);
      final sent = results[0] as Page<LikeRow>;
      final rows = results[1] as Page<ParticipationRow>;
      final channel = results[2] as ChannelDetail;

      liked.value = sent.content.any((r) => r.user.id == userId);

      // 멤버 = accepted 참가자 + 주최자. 주최자는 participations에 없다.
      final members = {
        ...rows.content.map((r) => r.user.id),
        channel.organizer.id,
      };
      final me = _auth.myId;
      bothMembers.value =
          me != null && members.contains(me) && members.contains(userId);
    } catch (_) {
      bothMembers.value = false;
    }
  }

  Future<void> _loadExchangeState() async {
    exchangeLoading.value = true;
    try {
      final results = await Future.wait([
        _myCardOrNull(),
        _api.myCardExchanges(size: 100),
      ]);
      myCard.value = results[0] as BusinessCard?;

      final list = (results[1] as Page<CardExchangeListItem>).content
          .where((e) => e.user.id == userId)
          .toList();
      // 같은 상대와 거절 이력 + 새 교환이 함께 있을 수 있다.
      // accepted > pending 순으로 고르고, rejected만 남으면 재요청 가능 상태로 둔다.
      exchange.value =
          list.firstWhereOrNull(
            (e) => e.status == CardExchangeStatus.accepted,
          ) ??
          list.firstWhereOrNull((e) => e.status == CardExchangeStatus.pending);
    } catch (_) {
      exchange.value = null;
    } finally {
      exchangeLoading.value = false;
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

  bool get isMe => _auth.myId == userId;

  /// 하단 명함 버튼이 어떤 상태여야 하는지.
  CardExchangeCta get exchangeCta {
    if (exchangeLoading.value || exchangePending.value) {
      return CardExchangeCta.loading;
    }
    if (myCard.value == null) return CardExchangeCta.noOwnCard;
    final e = exchange.value;
    if (e == null) return CardExchangeCta.active;
    if (e.status == CardExchangeStatus.accepted) return CardExchangeCta.done;
    // 상대가 나에게 보낸 요청이면 기다릴 게 아니라 내가 수락해야 한다.
    return e.direction == ExchangeDirection.received
        ? CardExchangeCta.incoming
        : CardExchangeCta.pending;
  }

  Future<void> toggleLike() async {
    if (likePending.value || !bothMembers.value) return;
    final next = !liked.value;
    liked.value = next;
    likePending.value = true;
    try {
      if (next) {
        await _api.like(slug, {'to_user_id': userId});
      } else {
        await _api.unlike(slug, userId);
      }
    } catch (e) {
      liked.value = !next;
      _toast.showError(e);
    } finally {
      likePending.value = false;
    }
  }

  Future<void> requestExchange() async {
    if (exchangePending.value) return;
    exchangePending.value = true;
    try {
      final res = await _api.requestCardExchange({'to_user_id': userId});
      _toast.success(
        res.status == CardExchangeStatus.accepted
            ? '명함을 교환했어요.'
            : '교환 요청을 보냈어요.',
      );
      await _loadExchangeState();
    } catch (e) {
      _toast.showError(e);
    } finally {
      exchangePending.value = false;
    }
  }

  Future<void> acceptExchange() async {
    final e = exchange.value;
    if (e == null || exchangePending.value) return;
    exchangePending.value = true;
    try {
      await _api.acceptCardExchange(e.id);
      _toast.success('${user.value?.nickname ?? ''}님과 명함을 교환했어요.');
      await _loadExchangeState();
    } catch (err) {
      _toast.showError(err);
    } finally {
      exchangePending.value = false;
    }
  }

  Future<void> openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast.error('링크를 열 수 없어요.');
    }
  }

  void openMyCards() => Get.toNamed(AppRoutes.meCards);

  /// 편집 화면은 저장·삭제에 성공하면 `result: true` 로 닫힌다
  /// (`MeCardsEditController` → `ToastService.backThen`).
  ///
  /// 그 신호를 받아 교환 상태만 다시 읽는다. 안 그러면 명함을 등록하고
  /// 돌아와도 CTA 가 "명함이 필요해요"에 멈춰 있다.
  /// `load()` 가 아니라 `_loadExchangeState()` 인 이유는 프로필까지 다시 받을
  /// 필요가 없고, isLoading 을 켜면 화면이 스켈레톤으로 깜빡이기 때문이다.
  Future<void> openCardEdit() async {
    final changed = await Get.toNamed<Object?>(AppRoutes.meCardsEdit);
    if (changed == true) await _loadExchangeState();
  }
}
