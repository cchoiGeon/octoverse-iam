# FCM 푸시 — 서버 요청사항

앱(Android)에 FCM을 붙이면서 서버에 필요한 것 **3가지**입니다.

---

## 0. Firebase 프로젝트 확인 (제일 먼저)

앱과 서버가 **같은 Firebase 프로젝트**를 써야 합니다. 다르면 앱이 발급받은 토큰을
서버가 알아보지 못해 발송이 **에러 없이 조용히 실패**합니다.

- 서버가 쓰는 Firebase 프로젝트 ID를 알려주세요.
- 앱은 그 프로젝트에 Android 앱(`kr.octoverse.iam`)으로 등록하겠습니다.

---

## 1. 디바이스 토큰 등록 / 해제 API

FCM은 "기기"로 보내는 구조라, 서버가 유저별 토큰을 들고 있어야 발송 대상을
특정할 수 있습니다. 지금 이 API가 없습니다.

```
POST /iam/v1/users/me/devices
  Authorization: Bearer <access token>
  body: { "token": "<fcm registration token>", "platform": "android" }
  → 200 OK
```

```
DELETE /iam/v1/users/me/devices/{token}
  Authorization: Bearer <access token>
  → 204 No Content
```

### 요구 동작

| 항목 | 내용 |
|---|---|
| **멱등성** | 같은 `(user, token)` 재전송 시 에러 없이 갱신만. 앱은 로그인·토큰갱신마다 무조건 POST를 쏩니다 |
| **다중 기기** | 한 유저가 여러 토큰을 가질 수 있어야 합니다(폰 + 태블릿) |
| **토큰 이관** | 같은 토큰이 **다른 유저**로 등록되면 이전 소유자에게서 떼어내야 합니다. 한 기기에서 A 로그아웃 → B 로그인 시 A의 푸시가 B에게 가는 사고를 막습니다 |
| **무효 토큰 정리** | 발송 시 FCM이 `UNREGISTERED` / `INVALID_ARGUMENT`를 주면 해당 토큰을 삭제해주세요. 앱 삭제한 기기의 토큰이 계속 쌓입니다 |

`platform`은 지금은 `"android"`만 보냅니다. iOS는 나중에 `"ios"`로 추가됩니다.

---

## 2. 발송 페이로드에 `data` 포함

`notification` 블록과 `data` 블록을 **둘 다** 넣어주세요.

```json
{
  "notification": {
    "title": "모임 24시간 전이에요",
    "body": "AI 밋업이 내일 오후 7시에 열려요"
  },
  "data": {
    "notification_id": "01H...",
    "type": "reminder_24h",
    "channel_slug": "ai-meetup"
  }
}
```

### 왜 둘 다인가

- `notification`만 → 앱이 백그라운드일 때 OS가 알아서 배너를 띄워주지만,
  **탭해도 홈으로만** 갑니다. 어느 모임 알림인지 앱이 알 방법이 없습니다.
- `data`만 → 딥링크는 되지만 백그라운드에서 앱을 깨워 직접 그려야 하고,
  국내 제조사 배터리 최적화에 눌려 **알림이 안 뜨는 기기**가 생깁니다.
- 둘 다 → 백그라운드는 OS가 안정적으로 표시하고, 탭하면 `data`로 정확한
  화면까지 보냅니다.

### `data` 필드 규격

| 키 | 필수 | 값 |
|---|---|---|
| `type` | ✅ | 아래 9종 중 하나. `GET /notifications`의 `type`과 **같은 값** |
| `notification_id` | ✅ | 해당 알림 레코드 id |
| `channel_slug` | 조건부 | 모임 관련 알림이면 필수. `welcome`·명함 관련은 생략 |

값은 전부 **문자열**이어야 합니다 (FCM `data`는 string map만 허용).

### type별 `channel_slug` 필요 여부

| type | `channel_slug` | 앱이 이동할 화면 |
|---|---|---|
| `participation_ack` | ✅ 필수 | 모임 상세 |
| `reminder_24h` | ✅ 필수 | 모임 상세 |
| `reminder_1h` | ✅ 필수 | 모임 상세 |
| `channel_updated` | ✅ 필수 | 모임 상세 |
| `channel_cancelled` | ✅ 필수 | 모임 상세 |
| `card_exchange_requested` | 불필요 | 명함함 |
| `card_exchange_accepted` | 불필요 | 명함함 |
| `card_exchange_cancelled` | 불필요 | 명함함 |
| `welcome` | 불필요 | 알림함 |

`channel_slug`가 빠지면 앱은 알림함으로 폴백합니다(크래시는 안 나지만 딥링크가 죽습니다).

---

## 참고 — 지금은 요청하지 않는 것

아래는 이번 범위 밖이지만, 나중에 생기면 앱에서 걷어낼 임시 처리들입니다.

- **알림 읽음 API** — 서버 응답에 `is_read`가 없고 읽음 처리 엔드포인트도 없어서,
  앱이 읽은 id를 로컬에 쌓아 머지하고 있습니다. 기기를 바꾸면 다시 안 읽음이 됩니다.
- **푸시 수신 설정** — `GET /users/me/settings`에 `email_notification_enabled`만
  있습니다. 푸시 on/off 토글을 붙이려면 `push_notification_enabled`가 필요합니다.
