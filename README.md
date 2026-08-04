# IAM Flutter

> **"만나기 전에, 이미 통하는 사이."** 오프라인 모임 직전 *사전 네트워킹* 앱.
> 한국어 전용 · 모바일 우선 · 코어 흐름: 사전 정찰 → 찜 → 현장 발견.

`IAM_web`(Next.js)의 Flutter 포팅. 구조는 사내 `Pickle` 앱 관례(GetX + Retrofit)를 따른다.

---

## 현재 상태 — 화면 25개 · DS 40개 전부 구현

Pixel 3a / API 34 에뮬레이터, Flutter 3.44.8, dev 서버(`dev-api.octoverse.kr`) 실연결.

```
dart analyze   →  No issues found!
flutter test   →  All tests passed! (41개)
```

| 영역 | 상태 |
|---|---|
| 라우트 25개 · 엔드포인트 40여 개 · DTO · enum · 디자인 토큰 | ✅ |
| 네트워크(401 단일 재시도) · 세션 · 참조 캐시 · 알림 · 토스트 | ✅ |
| 화면 25개 | ✅ |
| DS 위젯 40개 | ✅ |
| FCM 푸시(Android) · 권한 · 토큰 등록 · 딥링크 | ✅ |

**화면 25개**

| 영역 | 화면 |
|---|---|
| 진입 | `splash` · `login` · `onboarding`(3스텝) |
| 탐색 | `home`(검색·필터·정렬·무한스크롤) |
| 모임 | `event/detail` · `event/people` · `event/people_detail` |
| 주최 | `event/new` · `event/edit` · `event/manage` · `event/poster` |
| 현장 | `event/checkin` · `event/checkin_host` · `scan` |
| 마이 | `me/dashboard` · `me/meetings` · `me/likes` · `me/notifications` · `me/settings` |
| 프로필 | `me/profile` · `me/profile_career` · `me/profile_record` · `me/profile_link` |
| 명함 | `me/cards` · `me/cards_edit` |

**DS 40개**
`IamIcon`(32종) · `IamAvatar` · `IamTag` · `IamTagSelect` · `IamStatusBadge` · `IamCountBadge` ·
`IamVerifiedBadge`(계약만, 렌더 안 함) · `IamControlChip` · `IamFilterChip` · `IamSortSelect` ·
`IamButton` · `IamIconButton` · `IamKakaoLoginButton` · `IamFab` · `IamBottomCTABar` ·
`IamInput` · `IamTextarea` · `IamCheckbox` · `IamToggle` · `IamStepper` · `IamImageUpload` ·
`IamSegmentedControl` · `IamSearchBar` · `IamAppHeader` · `IamTabNav` · `IamNotificationBell` ·
`IamBottomSheet` · `IamDialog` · `IamToast` · `IamInfoBanner` · `IamListItem` · `IamEmptyState` ·
`IamSkeleton` · `IamEventCard` · `IamOrganizerEventCard` · `IamEventDetailHeader` ·
`IamNotificationItem` · `IamProfileCard` · `IamProfileDetail` · `IamLikeButton`

### 실기 검증 (dev 서버)

개발 로그인 → 홈 목록 → 내 모임(주최) → 공유 시트 4종 → 홍보포스터(배색 6종 · 소개 토글 ·
PNG 캡처 → 시스템 공유 시트) → 참가자 목록(9명) → 프로필 상세 → 찜 등록/해제(201/204)까지
실제 응답으로 확인했다. 명함 없는 계정에서 `GET /users/me/business-card` 404
(`BUSINESS_CARD_NOT_FOUND`)는 "명함 교환은 내 명함이 필요해요" 안내 + CTA 비활성으로 처리된다.

---

## 시작하기

**⚠️ 이 저장소에는 `android/` · `ios/` 폴더가 없다.** Flutter가 생성하는 파일이라
`flutter run` 전에 한 번 만들어야 한다. 폰트·카카오 설정까지 포함한 최초 1회 절차는
**[`NATIVE_SETUP.md`](./NATIVE_SETUP.md)** 에 있다.

설정을 마친 뒤 일상적인 실행:

```bash
flutter pub get

# ⚠️ 모델·ApiClient를 고쳤으면 반드시 실행한다.
#    안 돌리면 .g.dart가 없어 컴파일이 안 되고, 새 필드가 조용히 무시된다.
flutter pub run build_runner build --delete-conflicting-outputs

./scripts/run.sh          # 인자는 그대로 flutter run 에 넘어간다 (예: -d chrome)
```

`flutter run` 을 직접 치지 말고 **`scripts/run.sh`** 를 쓴다. 카카오 키는 주입 경로가
둘로 갈라져 있어서 손으로 치면 한쪽을 빠뜨리기 쉽다:

| 대상 | 주입 경로 |
|---|---|
| Android 네이티브 (리다이렉트 스킴 `kakao{key}://oauth`) | 환경변수 `KAKAO_NATIVE_KEY` → 없으면 `android/kakao.properties` |
| Dart 코드 (`kKakaoNativeKey` · 로그인 분기) | `--dart-define=KAKAO_NATIVE_KEY` **오직 이것만** |

`kakao.properties` 는 gradle 만 읽고 Dart 는 못 본다. 스크립트가 그 파일 한 곳을 읽어
양쪽에 같은 값을 흘려주므로 값을 두 군데 적을 일이 없다.
(Android Studio·IntelliJ 로 실행할 땐 `.idea/runConfigurations/main_dart.xml` 의
`additionalArgs` 가 같은 역할을 한다.)

`KAKAO_NATIVE_KEY`를 주지 않으면 **로그인 자체가 안 된다.** 키가 비면 `KakaoSdk.init`을
건너뛰므로 카카오 버튼을 눌러도 SDK 호출에서 실패한다. 예전에 있던 개발용 로그인
(`POST /auth/test/login`) 폴백은 이메일만으로 세션이 나오는 인증 우회라 **제거했다.**
서버 연동만 먼저 확인하려는 경우에도 카카오 키는 있어야 한다.

### 로컬 서버(iam-server)에 붙이기

```bash
# iam-server: npm run start:dev  (포트 3000, 프리픽스 /iam/v1)
API_BASE=http://10.0.2.2:3000/iam/v1 ./scripts/run.sh
```

⚠️ **에뮬레이터에서 호스트 PC는 `127.0.0.1`이 아니라 `10.0.2.2`다.**
`127.0.0.1`은 에뮬레이터 자기 자신을 가리킨다. (iOS 시뮬레이터는 호스트와
네트워크를 공유하므로 그냥 `localhost`를 쓰면 된다.)

평문 HTTP는 Android가 기본 차단하는데, `android/app/src/debug/AndroidManifest.xml`에
`usesCleartextTraffic="true"`를 넣어 뒀다. **debug 빌드에만** 적용되므로
릴리스는 그대로 막혀 있다.

서버는 dev(`https://dev-api.octoverse.kr/iam/v1`)에 붙는다. `API_BASE`를 주지 않으면
같은 값이 기본으로 쓰인다.

---

## 디렉터리

```
lib/
├── main.dart                    # 부트스트랩 + 전역 DI (웹 layout.tsx + providers.tsx)
│
├── common/
│   ├── constants/               # ✅ colors · typography · dimens · defines
│   ├── utils/                   # ✅ datetime(KST) · channel(phase·CTA·체크인 창)
│   └── widgets/ds/              # ✅ DS 40개 (8 카테고리 + barrel)
│
├── core/
│   ├── network/                 # ✅ apis · api_client(Retrofit) · dio · api_error
│   └── route/                   # ✅ app_routes · app_pages · route_guard
│
├── data/
│   ├── data_manager.dart        # ✅ GetStorage 래퍼 + barrel
│   ├── enums/                   # ✅ enum + 한국어 label
│   └── models/                  # ✅ DTO (.g.dart는 생성 필요)
│
├── service/                     # ✅ GetxService 4종 (웹 lib/services/*)
│
└── feature/                     # ✅ 화면 25개
    └── <화면>/
        ├── binding.dart         #   DI 등록
        ├── *_controller.dart    #   상태 + 비즈니스 로직
        └── *_view.dart          #   UI
```

---

## 웹 → Flutter 계층 대응

| IAM_web | IAM_flutter |
|---|---|
| `app/layout.tsx` · `providers.tsx` | `main.dart` |
| `app/**/page.tsx` (파일 라우팅) | `core/route/app_pages.dart` |
| `lib/api/client.ts` (fetch 래퍼) | `core/network/dio_configuration.dart` |
| `lib/services/errors.ts` | `core/network/api_error.dart` |
| `lib/services/auth.tsx` | `service/auth_service.dart` |
| `lib/services/reference.tsx` | `service/reference_service.dart` |
| `lib/services/toast.tsx` | `service/toast_service.dart` |
| `lib/services/notifications.ts` | `service/notification_service.dart` |
| `lib/services/route-guard.tsx` | `core/route/route_guard.dart` (GetX 미들웨어) |
| `lib/format/datetime.ts` | `common/utils/datetime_utils.dart` |
| `lib/format/channel.ts` | `common/utils/channel_utils.dart` |
| `types/api.ts` | `data/models/*` + `data/enums/*` |
| `lib/enums/labels.ts` | 각 enum의 `.label` getter |
| `components/ds/` | `common/widgets/ds/` |
| `hooks/*.ts` (TanStack Query) | **각 Controller** ← 아래 참고 |
| `lib/query/keys.ts` | *(대응 없음)* |
| `mocks/` (MSW) | *(대응 없음 — dev 서버 직접 연결)* |

---

## ⚠️ 포팅에서 가장 실수 나기 쉬운 곳: 쿼리 무효화

웹은 TanStack Query가 캐시·재조회·낙관적 업데이트를 대신했다. **GetX에는 그게 없다.**
웹 코드의 `qc.invalidateQueries(...)`를 만나면, 그 자리에서 *어느 컨트롤러의 무엇을 다시 부를지*
직접 정해야 한다. 아래가 그 대응표다.

| 액션 | 웹이 무효화한 것 | Flutter에서 해야 할 일 |
|---|---|---|
| 참가 신청 / 취소 | `channels.detail`, `channels.joined`, `notifications` | `EventDetailController.load()` + `MeMeetingsController` · `NotificationService` 갱신 |
| 찜 / 찜 해제 | `likes.sent(slug)`, `likes.mine`(prefix) | `EventPeopleController`의 `likedIds` 낙관적 갱신 → 실패 시 롤백 |
| 모임 생성·수정·삭제·종료 | `channels`(전체 prefix) | 홈 목록 + 내 모임 탭 무효화 플래그 |
| 프로필 저장 | `me` | `AuthService.refreshMe()` |
| 명함 교환 요청·수락·거절·취소 | `card-exchanges`(전체), `notifications` | `MeCardsController.load()` + `NotificationService.load()` |
| 체크인 성공 | `participations.list`, `channels.detail`, `checkin.info` | 세 컨트롤러 각각 `load()` |
| 설정 변경 | `settings`, `me` | `AuthService.refreshMe()` |

**권장 패턴** — 화면 간 갱신 신호는 `Get.find<XController>().needsRefresh = true` 같은 플래그보다,
컨트롤러에 `Future<void> load()`를 두고 돌아올 때 `await Get.toNamed(...)` 뒤에서 부르는 쪽이 안전하다.
(웹 `favorite_list_view.dart`가 `build()` 안에서 갱신하다 겪은 문제와 같은 함정을 피한다.)

---

## 규칙

### 토큰만 쓴다
`AppColors` · `AppDimens` · `AppTypography` · `AppShadows` · `AppMotion`만 참조한다.
하드코딩 `Color(0xFF...)` · raw px 금지. Figma 변수(`3.UI` node 16:4)와 이름·값이 1:1로 일치한다.

### K2 — 본인인증 제외
`IamVerifiedBadge`와 아바타 인증 도트는 **전 화면에서 렌더하지 않는다.**
prop·토큰은 계약상 유지하되 그리지 않는다.

### DS로만 조합한다
화면은 `package:iam/common/widgets/ds/ds.dart`의 위젯으로만 만든다. 애드혹 스타일 금지.
이름에 `Iam` 접두사를 붙인 이유는 Material의 `Icon`·`Checkbox`·`Dialog`·`Stepper`·`SearchBar`와
겹쳐 import 충돌이 나기 때문이다.

### 모임 상태는 서버 status를 믿지 않는다
서버에 자동 종료 배치가 없어 이미 끝난 모임도 `status="open"`으로 남는다.
표시는 항상 `ChannelUtils.phaseOf()` 결과(`open/soon/full/live/past`)를 쓴다.

### 체크인은 낙관적 업데이트 금지
v1엔 정정 경로가 없다. 서버 200 이전에 성공을 보여선 안 된다.
반대로 찜은 낙관적 갱신 대상이다(되돌릴 수 있으므로).

### source of truth
- 동작·데이터·규칙 → `IAM_web/.docs/0_planning/` (PRD · ERD · REST API) + Swagger `/iam/docs`
- 시각·레이아웃 → Figma `3.UI` (node 16:4) + `IAM_web/src/styles/tokens/`
- 충돌하면 멈추고 확인한다.

---

## 웹·Figma와 알아둘 차이

| 항목 | 내용 |
|---|---|
| **인증 경로** | 웹은 카카오 authorize 리다이렉트(서버가 콜백 소유 · HttpOnly 쿠키). 앱은 네이티브 SDK로 `id_token`을 받아 `POST /auth/oauth/kakao`. **계약(REST §1.1)은 같고 토큰 획득 경로만 다르다.** |
| **스플래시** | 웹엔 없다(RouteGuard가 대신). 앱은 `/splash`에서 세션 확인 후 분기한다. |
| **랜딩 분리** | 웹은 `/`에서 로그인 여부로 Landing/Explore를 갈랐다. 앱은 `/login`과 `/`로 분리해 스택 제어를 단순화했다. |
| **폰트** | Figma 시안은 Noto Sans KR을 스탠드인으로 쓴다. 실제는 Pretendard다 — **시안의 행간(leading)을 그대로 옮기면 어긋난다.** `AppTypography` 값을 따른다. |
| **포스터 에디터** | `/event/:slug/poster`는 **Figma 시안이 없다**(공유 시트의 진입점만 존재). 웹 `components/app/poster/*` 구현을 기준으로 삼는다. |
| **MSW** | 웹의 오프라인 mock 계층은 옮기지 않았다. dev 서버에 직접 붙는다. |
| **`/me/test`** | 웹의 dev 전용 테스트 허브는 옮기지 않았다. |

---

## 실행해보고 잡은 함정 (같은 실수 반복 방지)

| 증상 | 원인 | 규칙 |
|---|---|---|
| 스플래시에서 영구 정지 | `SplashView`가 `controller`를 안 읽어 `lazyPut` 컨트롤러가 생성되지 않음 → `onReady()` 미실행 | **뷰가 컨트롤러를 참조하지 않으면 `Get.put`(eager)을 쓴다** |
| 탭바가 화면 전체를 먹고 본문 사라짐 | `Row(crossAxisAlignment: stretch)`가 `bottomNavigationBar`의 최대 높이(화면 전체)까지 늘어남 | **stretch Row는 높이를 고정한다** |
| 태그가 세로로 쌓임 | `Container`에 `alignment`를 주면 최대 너비를 차지 | **pill은 `alignment` 대신 패딩으로 크기를 만든다** |
| 시각이 "PM 7:18" | intl 0.20의 `ko` 로케일 AMPMS가 "AM"/"PM" (CLDR 42 변경). 웹·Figma는 "오후" | **오전/오후는 `DateTimeUtils.time()`이 직접 조립한다** |
| `Page` 이름 충돌 | 페이징 DTO `Page<T>` vs Flutter 네비게이터의 `Page` | **`import 'package:flutter/widgets.dart' hide Page;`** |
| 코드 생성 실패 | `retrofit_generator` 9.x + `retrofit` 4.9.x는 `Parser.DartMappable` 미인식 | **generator는 `^10.2.8` — retrofit과 세대를 맞춘다** |
| 카카오 인증은 끝났는데 "계속하기"에서 멈춤 | 패키지명 변경(`kr.octoverse.iam` → `com.octoverse.iam`) **전 빌드가 기기에 남아** 같은 `kakao{키}://oauth` 스킴을 선언 → 콜백이 구 패키지로 배달돼 `No uri was passed to CustomTabsActivity` 로 죽는다. 현재 빌드는 콜백을 영영 못 받는다 | **패키지명을 바꾸면 구 패키지를 지운다** — `adb uninstall kr.octoverse.iam`. 재설치로는 안 없어진다(다른 앱으로 취급된다) |

에뮬레이터에서 DNS가 죽어 서버 연결이 안 되면(ICMP는 되는데 도메인 해석만 멈춤)
`-dns-server 8.8.8.8,1.1.1.1` 로 재기동한다. 앱 문제가 아니다.

---

## 남은 빚

| 위치 | 내용 |
|---|---|
| 홈 · 모임 상세 | 모임 phase가 진입 시점 고정 — 웹의 `useNow()`처럼 60초 티커가 없어 "모집중 → 진행 중" 자동 전환이 안 된다. 화면을 다시 열면 갱신된다. |
| 알림 읽음 | 서버에 `is_read`도 읽음 처리 엔드포인트도 없어 로컬(`Storage.readNotificationIds`)에 둔다. 기기를 바꾸면 다시 안 읽음이 된다. |
| 푸시 on/off | 서버 `settings`에 `push_notification_enabled`가 없어 앱 안에서 끌 방법이 없다. OS 알림 설정으로만 끈다. |
| `event/poster` | **Figma 시안이 없다.** 웹 `components/app/poster/*` 기준으로 옮겼다 — 시안이 나오면 맞춰야 한다. |
| 참가 QR 저장 | 웹의 "QR 코드 저장"(다운로드)은 옮기지 않았다. 갤러리 쓰기 권한 + 플러그인이 필요한데, 링크 복사와 홍보포스터 공유로 대체된다. |
| 프로필 PATCH | 서버가 **전체 치환**이라 건드리지 않은 배열도 다시 보내야 한다(`ProfileItemSaver.carryOver()`). 새 하위 폼을 추가하면 여기도 같이 고쳐야 한다. |
