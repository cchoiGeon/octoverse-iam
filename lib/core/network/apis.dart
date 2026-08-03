/// REST 엔드포인트 경로 상수.
/// `IAM_web/src/lib/api/*` + Swagger(`/iam/docs`) 기준. base = `/iam/v1`.
///
/// 값은 모두 `const` — Retrofit 애노테이션(`@GET(Apis.xxx)`)에 그대로 넣기 위해서다.
/// `{slug}` 같은 자리는 Retrofit이 `@Path('slug')` 인자로 채운다.
///
/// 웹은 경로를 훅 안에 인라인으로 두지만, Pickle 관례를 따라 여기에 모은다.
abstract final class Apis {
  // ── §1 Auth ────────────────────────────────────────────────
  /// OIDC id_token 전송. provider = kakao | google | apple.
  static const String oauthLogin = '/auth/oauth/{provider}';

  static const String signup = '/auth/signup';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String withdraw = '/auth/withdraw';

  // ── §2 Common ──────────────────────────────────────────────
  /// multipart 이미지 업로드 → { url }
  static const String images = '/common/images';

  // ── §3·§4 User / Profile / Settings ────────────────────────
  static const String me = '/users/me';
  static const String meProfile = '/users/me/profile';
  static const String meSettings = '/users/me/settings';
  static const String user = '/users/{userId}';

  // ── §5 Channel (모임) ──────────────────────────────────────
  static const String channels = '/channels';
  static const String channel = '/channels/{slug}';
  static const String channelClose = '/channels/{slug}/close';
  static const String channelsOrganized = '/channels/me/organized';
  static const String channelsJoined = '/channels/me/joined';

  // ── §6 Participation (참가) ────────────────────────────────
  static const String participations = '/channels/{slug}/participations';
  static const String participation = '/channels/{slug}/participations/{id}';
  static const String participationMine = '/channels/{slug}/participations/me';
  static const String myParticipations = '/users/me/participations';

  // ── Check-in (check-in api-contract C.1·C.2) ───────────────
  /// GET = 주최자 코드·창·카운터 / POST = 코드 제출.
  static const String checkin = '/channels/{slug}/checkin';

  // ── §7 Like (찜) ───────────────────────────────────────────
  static const String likes = '/channels/{slug}/likes';
  static const String unlike = '/channels/{slug}/likes/{toUserId}';
  static const String likesSent = '/channels/{slug}/likes/sent';
  static const String likesReceived = '/channels/{slug}/likes/received';
  static const String myLikes = '/users/me/likes';

  // ── §8 Notification ────────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Device (FCM 푸시 토큰) ─────────────────────────────────
  /// 이 기기의 FCM 토큰 등록. 멱등 — 같은 토큰 재전송은 갱신만 한다.
  static const String devices = '/users/me/devices';

  /// 로그아웃 시 해제. 계약은 `docs/server-requirements-fcm.md` §1.
  static const String device = '/users/me/devices/{token}';

  // ── Business Card & Exchange ───────────────────────────────
  /// GET·PUT(upsert)·DELETE — owner당 1개인 단일 리소스.
  static const String myBusinessCard = '/users/me/business-card';
  static const String cardExchanges = '/card-exchanges';
  static const String cardExchange = '/card-exchanges/{id}';
  static const String cardExchangeAccept = '/card-exchanges/{id}/accept';
  static const String cardExchangeReject = '/card-exchanges/{id}/reject';
  static const String myCardExchanges = '/users/me/card-exchanges';

  // ── §9 Reference ───────────────────────────────────────────
  static const String interestTags = '/interest-tags';
  static const String eventCategories = '/event-categories';
  static const String skillTags = '/skill-tags';
}
