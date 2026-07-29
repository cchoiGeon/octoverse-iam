# Firebase 설정 (Android) — 최초 1회

FCM 푸시를 붙이기 전에 콘솔에서 해야 하는 일. **여기까지는 코드로 대신할 수 없다.**

이 문서를 끝내면 `android/app/google-services.json` 이 생기고, 그때부터 앱 구현을
이어갈 수 있다 (`docs/superpowers/plans/2026-07-29-fcm-push-android.md` Task 1).

관련 문서
- 서버팀에 넘길 요청서 — [`server-requirements-fcm.md`](server-requirements-fcm.md)
- 앱 설계 — [`superpowers/specs/2026-07-29-fcm-push-design.md`](superpowers/specs/2026-07-29-fcm-push-design.md)

---

## 필요한 것

| # | 항목 | 없으면 |
|---|---|---|
| 1 | Firebase 프로젝트 (**서버와 같은 것**) | 토큰이 안 맞아 발송이 **에러 없이** 실패한다 |
| 2 | 그 프로젝트에 등록된 Android 앱 (`kr.octoverse.iam`) | `google-services.json` 을 받을 수 없다 |
| 3 | `android/app/google-services.json` | `flutter build` 가 `File google-services.json is missing` 으로 실패 |
| 4 | 서버용 서비스 계정 키 (서버팀 몫) | 서버가 FCM 에 발송 요청을 못 보낸다 |

**필요 없는 것** — SHA-1 인증서 지문. Google 로그인·Dynamic Links·전화 인증에는
필요하지만 **FCM 은 요구하지 않는다.** 콘솔이 선택 입력으로 물어보면 비워두고 넘어간다.

---

## 0. 먼저 확인할 것 — 서버가 쓰는 프로젝트

**이 단계를 건너뛰면 나중에 원인 찾기가 제일 괴로운 종류의 버그가 난다.**

FCM 토큰은 Firebase 프로젝트에 묶여 있다. 앱이 A 프로젝트에서 받은 토큰을
서버가 B 프로젝트 자격으로 발송하면, FCM 은 `SenderId mismatch` 를 돌려주거나
그냥 조용히 버린다. 앱에는 아무 로그도 남지 않는다.

서버팀에 물어볼 것:

> "FCM 발송에 쓰는 Firebase 프로젝트 ID가 뭔가요? 앱을 같은 프로젝트에 등록해야 합니다."

- **이미 있다** → 그 프로젝트에 초대받고 §2 로 간다
- **아직 없다** → §1 에서 만들고, 만든 프로젝트 ID를 서버팀에 준다

---

## 1. Firebase 프로젝트 생성 (없을 때만)

[console.firebase.google.com](https://console.firebase.google.com) → **프로젝트 추가**

1. 이름: `iam` (또는 팀 관례에 맞게)
2. **Google 애널리틱스는 꺼도 된다.** FCM 동작과 무관하고, 켜면 계정 연결 단계가 는다
3. 생성 후 상단의 **프로젝트 ID** 를 서버팀에 전달

---

## 2. Android 앱 등록

프로젝트 개요 → **앱 추가** → Android 아이콘

| 입력란 | 값 | 비고 |
|---|---|---|
| Android 패키지 이름 | `kr.octoverse.iam` | **정확히 일치해야 한다** (아래 참고) |
| 앱 닉네임 | `IAM Android` | 콘솔 표시용, 아무거나 |
| 디버그 서명 인증서 SHA-1 | **비워둔다** | FCM 은 필요 없다 |

패키지명은 `android/app/build.gradle.kts` 의 `applicationId` 와 같아야 한다.
현재 값 확인:

```bash
grep applicationId android/app/build.gradle.kts
# applicationId = "kr.octoverse.iam"
```

한 글자라도 다르면 빌드할 때 gradle 이
`No matching client found for package name` 으로 잡아준다.

---

## 3. google-services.json 배치

콘솔이 주는 다운로드 버튼으로 파일을 받아 **`android/app/`** 에 넣는다.
(`android/` 가 아니다. 한 단계 더 들어간 `android/app/` 이다.)

```bash
mv ~/Downloads/google-services.json android/app/google-services.json

# 패키지명이 맞는지 확인
grep -o '"package_name": "[^"]*"' android/app/google-services.json
# "package_name": "kr.octoverse.iam"
```

콘솔의 안내는 여기서 gradle 설정을 이어서 시키는데, **그건 하지 않는다.**
Task 1 이 코드로 처리한다.

### 이 파일은 커밋한다

`.gitignore` 가 기본으로 이 파일을 제외하고 있는데, Task 1 에서 그 줄을 지운다.

담겨 있는 API 키는 **클라이언트 식별자**이지 비밀이 아니다. 발송 권한을 가진 건
§5 의 서비스 계정 키 쪽이고, 그건 서버에만 있다. 커밋하지 않으면 다른 개발자와
CI 빌드가 전부 깨지고, 그 사실은 남이 클론했을 때야 드러난다.

저장소 밖에 두는 `kakao.properties` 와는 성격이 다르다.

---

## 4. 알림 아이콘 (선택 — 나중에 해도 된다)

지정하지 않으면 Android 가 앱 아이콘을 쓰는데, **상태바에서 흰 사각형으로만 보인다.**
Android 는 알림 아이콘의 색을 무시하고 알파 채널만 쓰기 때문이다.

제대로 하려면 투명 배경에 흰색 실루엣만 있는 PNG 를 만들어
`android/app/src/main/res/drawable-*/ic_notification.png` 로 넣고 매니페스트에
`com.google.firebase.messaging.default_notification_icon` 을 추가한다.

푸시 동작 자체와는 무관하니 급하지 않다. 디자인 나오면 그때 붙인다.

---

## 5. 서버팀이 받아야 할 것

앱이 아니라 **서버**가 필요로 하는 자격증명이다. 참고용으로만 적는다.

프로젝트 설정 → **서비스 계정** → **새 비공개 키 생성** → JSON 다운로드

⚠️ **이건 진짜 비밀이다.** 이 키가 있으면 누구나 이 앱 사용자 전원에게 푸시를
보낼 수 있다. 저장소에 넣지 말고 서버 비밀 관리 체계(환경변수·시크릿 매니저)로 넘긴다.

Legacy 서버 키(`AAAA...`)는 2024년에 지원이 끝났다. 서버팀이 그걸 달라고 하면
서비스 계정 JSON 을 쓰는 HTTP v1 API 로 가야 한다고 알려준다.

---

## 6. 확인

여기까지 하고 Task 1 을 돌리면 빌드가 통과해야 한다.

```bash
flutter build apk --debug
```

| 결과 | 뜻 |
|---|---|
| `✓ Built build/app/outputs/flutter-apk/app-debug.apk` | 성공 |
| `File google-services.json is missing` | §3 의 위치가 틀렸다 (`android/app/` 인지 확인) |
| `No matching client found for package name` | §2 의 패키지명이 `applicationId` 와 다르다 |

---

## 7. 테스트 푸시 보내는 법

앱 구현(Task 4)이 끝난 뒤에 쓴다. 서버 없이 앱만으로 수신을 검증하는 방법이다.

**① 기기 토큰 얻기** — 앱을 실행하고 로그인하면 `POST /users/me/devices` 요청이
나간다. `flutter run` 콘솔의 PrettyDioLogger 출력에서 요청 본문의 `token` 값을 복사한다.

**② 발송** — Firebase 콘솔 → **Messaging** → 첫 캠페인 만들기 → **Firebase 알림 메시지**

1. 제목·본문 입력
2. 우측 **테스트 메시지 전송** → ①의 토큰 붙여넣기
3. **딥링크를 확인하려면 커스텀 데이터를 꼭 넣는다:**

| 키 | 값 |
|---|---|
| `type` | `reminder_24h` |
| `channel_slug` | 실제 존재하는 모임 slug |

커스텀 데이터 없이 보내면 알림은 뜨지만 탭했을 때 알림함으로만 간다.
그건 버그가 아니라 설계대로다 (`docs/server-requirements-fcm.md` §2 참고).

---

## 자주 나는 문제

| 증상 | 원인 |
|---|---|
| 알림이 아예 안 온다 | 앱과 서버의 Firebase 프로젝트가 다르다 (§0). 콘솔 테스트 발송은 되는데 서버 발송만 안 되면 거의 이 경우다 |
| 콘솔이 `Invalid registration token` | 토큰이 만료됐거나 로그아웃으로 무효화됐다. 앱을 다시 실행해 새 토큰을 받는다 |
| 알림은 오는데 탭하면 홈으로만 간다 | `data` 페이로드가 없다. 콘솔이면 커스텀 데이터, 서버면 요청서 §2 |
| 상태바 아이콘이 흰 사각형 | §4 미설정. 정상 동작이다 |
| 앱이 떠 있을 때만 안 뜬다 | 포그라운드 표시는 Task 5 담당. 그 태스크 전이면 정상 |
| Android 13+ 에서 권한 팝업이 안 뜬다 | 온보딩 마지막 스텝에서만 뜬다. 이미 온보딩을 마친 계정이면 설정 → 앱 → IAM → 알림에서 직접 켠다 |
