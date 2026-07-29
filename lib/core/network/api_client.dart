import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:iam/data/data_manager.dart';

import 'apis.dart';

part 'api_client.g.dart';

/// 서버 API 인터페이스 — Retrofit이 `api_client.g.dart`에 구현을 생성한다.
///
/// 웹의 `IAM_web/src/hooks/*.ts`(TanStack Query 훅)가 호출하던 엔드포인트를
/// 그대로 옮긴 것이다. **차이**: 웹은 훅이 캐시·무효화까지 맡지만 여기서는
/// 순수 호출만 하고, 캐시·갱신은 각 Controller가 책임진다.
///
/// ⚠️ 이 파일을 고치면 반드시 코드 생성을 다시 돌린다:
///   flutter pub run build_runner build --delete-conflicting-outputs
///
/// ⚠️ **`@RestApi`에 baseUrl을 주지 않는다.** 서버 주소는 Dio의
///    `BaseOptions.baseUrl`(dio_configuration.dart)이 런타임에 정한다.
///
///    애노테이션에 `baseUrl: kApiBase`를 주면 생성기가 **코드 생성 시점의
///    값을 문자열 리터럴로 박아버린다**(`baseUrl ??= 'https://dev-api...'`).
///    게다가 생성 코드의 `_combineBaseUrls`는 그 값이 절대 URL이면 Dio 설정을
///    덮어쓴다. 결과적으로 `--dart-define=API_BASE=...`가 조용히 무시돼
///    어떤 환경으로 빌드하든 항상 dev 서버로 붙는다.
@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ══════════════════════════════════════════════════════════
  // §1 Auth
  // ══════════════════════════════════════════════════════════

  /// 1.1 소셜 로그인 — 네이티브 SDK로 받은 OIDC id_token 전송.
  /// 웹은 authorize 리다이렉트(서버가 콜백 소유)지만 앱은 이 경로를 직접 쓴다.
  @POST(Apis.oauthLogin)
  Future<OAuthLoginResponse> oauthLogin(
    @Path('provider') String provider,
    @Body() OAuthLoginRequest body,
  );

  /// 1.7 개발용 로그인. 카카오 키가 없을 때 진입 경로.
  @POST(Apis.testLogin)
  Future<OAuthLoginResponse> testLogin(@Body() TestLoginRequest body);

  /// 1.2 약관 동의 · 가입 완료.
  @POST(Apis.signup)
  Future<SignupResponse> signup(@Body() SignupRequest body);

  /// 1.3 토큰 갱신. 401(TOKEN_EXPIRED) 시 인터셉터가 1회 호출한다.
  @POST(Apis.refresh)
  Future<RefreshResponse> refresh(@Body() Map<String, dynamic> body);

  @POST(Apis.logout)
  Future<void> logout();

  @DELETE(Apis.withdraw)
  Future<void> withdraw();

  // ══════════════════════════════════════════════════════════
  // §2 Common
  // ══════════════════════════════════════════════════════════

  /// 2.1 이미지 업로드 → { url }. JPG/PNG · 5MB 이하.
  @MultiPart()
  @POST(Apis.images)
  Future<ImageUploadResponse> uploadImage(@Part(name: 'file') File file);

  // ══════════════════════════════════════════════════════════
  // §3·§4 User / Profile / Settings
  // ══════════════════════════════════════════════════════════

  /// 3.1 내 계정. 세션 확인도 겸한다(200=로그인 / 401=비로그인).
  @GET(Apis.me)
  Future<Me> me();

  /// 3.4 타 유저 공개 프로필.
  @GET(Apis.user)
  Future<PublicUser> user(@Path('userId') String userId);

  /// 3.2 프로필 생성(온보딩). 배열은 통째로 설정된다.
  @POST(Apis.meProfile)
  Future<Profile> createProfile(@Body() ProfileCreateRequest body);

  /// 3.3 프로필 수정 — **전체 교체**.
  /// 보낸 배열은 통째 교체, null이면 삭제, 생략하면 변경 없음.
  /// ⚠️ 부분 수정 화면에서도 기존 배열을 모두 실어 보내야 유실되지 않는다.
  @PATCH(Apis.meProfile)
  Future<Profile> updateProfile(@Body() ProfileUpdateRequest body);

  @GET(Apis.meSettings)
  Future<UserSettings> settings();

  @PATCH(Apis.meSettings)
  Future<UserSettings> updateSettings(@Body() SettingsUpdateRequest body);

  // ══════════════════════════════════════════════════════════
  // §5 Channel (모임)
  // ══════════════════════════════════════════════════════════

  /// 5.1 공개 모임 목록.
  /// ⚠️ sort는 start_at/created_at만 지원한다. 인기순·가나다순은 클라 정렬.
  @GET(Apis.channels)
  Future<Page<ChannelListItem>> channels({
    @Query('q') String? q,
    @Query('category') String? category,
    @Query('interest') String? interest,
    @Query('sort') String? sort,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET(Apis.channel)
  Future<ChannelDetail> channel(@Path('slug') String slug);

  @POST(Apis.channels)
  Future<ChannelDetail> createChannel(@Body() ChannelCreateRequest body);

  @PATCH(Apis.channel)
  Future<ChannelDetail> updateChannel(
    @Path('slug') String slug,
    @Body() ChannelUpdateRequest body,
  );

  @DELETE(Apis.channel)
  Future<void> deleteChannel(@Path('slug') String slug);

  /// 5.6 주최자 수동 종료. 되돌릴 수 없다.
  @POST(Apis.channelClose)
  Future<CloseChannelResponse> closeChannel(@Path('slug') String slug);

  /// 5.7 내가 주최한 모임.
  @GET(Apis.channelsOrganized)
  Future<Page<ChannelListItem>> myOrganizedChannels({
    @Query('page') int? page,
    @Query('size') int? size,
  });

  /// 5.8 내가 참가한 모임 — my_participation이 함께 온다.
  @GET(Apis.channelsJoined)
  Future<Page<JoinedChannelListItem>> myJoinedChannels({
    @Query('participation_status') String? participationStatus,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  // ══════════════════════════════════════════════════════════
  // §6 Participation (참가)
  // ══════════════════════════════════════════════════════════

  /// 6.3 참가자 목록.
  /// ⚠️ 허용 쿼리는 page/size/status 뿐 — sort를 넘기면 400(VALIDATION_ERROR).
  @GET(Apis.participations)
  Future<Page<ParticipationRow>> participants(
    @Path('slug') String slug, {
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  /// 6.1 참가 신청 (MVP는 자동 승인).
  @POST(Apis.participations)
  Future<ParticipationCreateResponse> joinChannel(@Path('slug') String slug);

  /// 6.2 참가 취소.
  @DELETE(Apis.participationMine)
  Future<void> leaveChannel(@Path('slug') String slug);

  /// 6.4 승인·거절 (주최자).
  @PATCH(Apis.participation)
  Future<ParticipationRow> updateParticipation(
    @Path('slug') String slug,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  /// 6.5 내 신청 대기 목록.
  @GET(Apis.myParticipations)
  Future<Page<MyParticipation>> myParticipations();

  // ══════════════════════════════════════════════════════════
  // Check-in
  // ══════════════════════════════════════════════════════════

  /// C.1 주최자 체크인 정보(6자리 코드·창·카운터). 주최자만 200.
  @GET(Apis.checkin)
  Future<CheckInInfo> checkInInfo(@Path('slug') String slug);

  /// C.2 코드 제출.
  /// ⚠️ 낙관적 업데이트 금지 — v1엔 정정 경로가 없어 서버 200 전에는
  ///    성공을 보여선 안 된다.
  @POST(Apis.checkin)
  Future<CheckInResult> submitCheckIn(
    @Path('slug') String slug,
    @Body() Map<String, dynamic> body,
  );

  // ══════════════════════════════════════════════════════════
  // §7 Like (찜)
  // ══════════════════════════════════════════════════════════

  @POST(Apis.likes)
  Future<LikeCreateResponse> like(
    @Path('slug') String slug,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(Apis.unlike)
  Future<void> unlike(
    @Path('slug') String slug,
    @Path('toUserId') String toUserId,
  );

  /// 7.3 이 모임에서 내가 찜한 사람 — 참가자 목록의 ♥ 상태를 만든다.
  @GET(Apis.likesSent)
  Future<Page<LikeRow>> channelSentLikes(@Path('slug') String slug);

  /// 7.4 이 모임에서 나를 찜한 사람.
  @GET(Apis.likesReceived)
  Future<Page<LikeRow>> channelReceivedLikes(@Path('slug') String slug);

  /// 7.5 내 찜 전체 (찜 관리 화면).
  @GET(Apis.myLikes)
  Future<Page<MyLikeRow>> myLikes({@Query('direction') String? direction});

  // ══════════════════════════════════════════════════════════
  // §8 Notification
  // ══════════════════════════════════════════════════════════

  /// 8.1 알림 목록(최신순).
  /// ⚠️ 실서버 응답에 is_read가 없고 읽음 API도 없다 → 읽음 상태는
  ///    `kStorageNotificationRead`에 로컬 보관 후 머지한다.
  @GET(Apis.notifications)
  Future<Page<NotificationRow>> notifications({@Query('size') int? size});

  // ══════════════════════════════════════════════════════════
  // Device (FCM 푸시 토큰)
  // ══════════════════════════════════════════════════════════

  /// 이 기기의 FCM 토큰을 등록한다. 멱등이라 로그인·토큰갱신마다 그냥 쏜다.
  ///
  /// ⚠️ 비로그인 상태에서 부르면 안 된다. 401 이 인터셉터를 타면 세션이
  ///    끊긴 것으로 처리돼 사용자가 로그인 화면으로 튕긴다.
  @POST(Apis.devices)
  Future<void> registerDevice(@Body() DeviceRegisterRequest body);

  /// 로그아웃 시 해제. 안 하면 로그아웃한 기기로 계속 푸시가 간다.
  @DELETE(Apis.device)
  Future<void> unregisterDevice(@Path('token') String token);

  // ══════════════════════════════════════════════════════════
  // Business Card & Exchange
  // ══════════════════════════════════════════════════════════

  /// 내 명함. 미등록이면 404 → Controller가 null로 변환한다(오류 아님).
  @GET(Apis.myBusinessCard)
  Future<BusinessCard> myBusinessCard();

  /// 등록·수정 동일 (PUT upsert).
  @PUT(Apis.myBusinessCard)
  Future<BusinessCard> upsertBusinessCard(
    @Body() BusinessCardUpsertRequest body,
  );

  @DELETE(Apis.myBusinessCard)
  Future<void> deleteBusinessCard();

  /// 교환 요청. 역방향 pending이 있으면 서버가 자동 수락한다.
  @POST(Apis.cardExchanges)
  Future<CardExchangeResponse> requestCardExchange(
    @Body() Map<String, dynamic> body,
  );

  @POST(Apis.cardExchangeAccept)
  Future<CardExchangeResponse> acceptCardExchange(@Path('id') String id);

  @POST(Apis.cardExchangeReject)
  Future<CardExchangeResponse> rejectCardExchange(@Path('id') String id);

  /// 요청 취소(요청자·pending).
  @DELETE(Apis.cardExchange)
  Future<void> cancelCardExchange(@Path('id') String id);

  /// 교환 목록. 탭별로 direction·status를 달리 준다.
  /// 명함첩=status accepted / 받은=received+pending / 보낸=sent
  @GET(Apis.myCardExchanges)
  Future<Page<CardExchangeListItem>> myCardExchanges({
    @Query('direction') String? direction,
    @Query('status') String? status,
    @Query('size') int? size,
  });

  // ══════════════════════════════════════════════════════════
  // §9 Reference — version으로 캐시한다
  // ══════════════════════════════════════════════════════════

  @GET(Apis.interestTags)
  Future<InterestTagsResponse> interestTags();

  @GET(Apis.eventCategories)
  Future<EventCategoriesResponse> eventCategories();

  @GET(Apis.skillTags)
  Future<SkillTagsResponse> skillTags();
}
