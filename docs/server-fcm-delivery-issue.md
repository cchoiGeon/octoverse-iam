# FCM 푸시가 기기에 도달하지 않습니다

- 확인 일시: 2026-07-30
- 환경: dev (`https://dev-api.octoverse.kr/iam/v1`)
- 계약 문서: [`server-requirements-fcm.md`](server-requirements-fcm.md)

---

## 요약

디바이스 토큰 등록 API(§1)는 **정상 동작합니다.** 감사합니다.

그런데 **알림 레코드는 생성되는데 FCM 메시지가 기기까지 오지 않습니다.**

```
POST /channels/llm-d8802a/participations   → 201
GET  /notifications                        → participation_ack 즉시 나타남  ✅
기기                                        → 아무것도 안 옴               ❌
```

앱 쪽은 준비가 끝난 상태로 확인했습니다(아래 §2). 막힌 구간은
**"알림 레코드 생성 → FCM 발송"** 한 곳입니다.

---

## 1. 재현 절차

그대로 복사해서 돌리시면 됩니다.

```bash
BASE=https://dev-api.octoverse.kr/iam/v1
TOKEN=$(curl -s -X POST "$BASE/auth/test/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"new+1785343447238@iam.app"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['access_token'])")

# 참가 신청 → participation_ack 발생
curl -s -X POST "$BASE/channels/ai-ed1ee9/participations" \
  -H "Authorization: Bearer $TOKEN"

# 레코드는 즉시 생깁니다
curl -s "$BASE/notifications?size=1" -H "Authorization: Bearer $TOKEN"
```

이 계정(`new+1785343447238@iam.app`)에는 실제 Android 기기 토큰이 등록돼 있습니다.

결과: 레코드는 생성됨. 기기에는 25초 기다려도 아무것도 도착하지 않음.
3회 반복(`ai-ed1ee9`, `llm-d8802a`, `6-22-f3fda5`) 모두 동일.

---

## 2. 앱 쪽은 정상입니다 (확인 완료)

발송만 되면 그릴 수 있는 상태라는 걸 기기에서 직접 확인했습니다.

| 확인 항목 | 결과 |
|---|---|
| FCM 토큰 발급 | 성공 (= 기기가 FCM에 정상 등록됨) |
| `POST /users/me/devices` | `200 OK`, 앱 재시작 2회 모두 |
| 알림 권한 | `POST_NOTIFICATIONS: granted=true` |
| 알림 채널 | `mId='iam_default', mImportance=4` |
| Firebase 초기화 | `FirebaseApp initialization successful` |
| **FCM 상시 연결** | **ESTABLISHED** (아래) |
| **FCM 수신 로그(logcat)** | **0줄** ← 메시지가 기기까지 안 옴 |

### 기기의 FCM 수신 통로는 열려 있습니다

"에뮬레이터라서 못 받는 것 아니냐"를 배제하기 위해 직접 확인했습니다.

```
$ netstat -an | grep 5228
tcp6  ::ffff:10.0.2.16:60570  ::ffff:64.233.189.x:5228  ESTABLISHED
                                                ↑ 구글 IP
$ dumpsys activity services com.google.android.gms | grep -i gcm
  * ServiceRecord{...  com.google.android.gms/.gcm.GcmService}
  * ServiceRecord{...  com.google.android.gms/.gcm.nts.SchedulerService}

Play 서비스 버전: 23.18.18
```

**5228은 FCM의 상시 연결 포트입니다.** 이 소켓이 ESTABLISHED이고 `GcmService`가
동작 중이라는 것은, 기기가 FCM 메시지를 **받을 준비가 된 채로 대기 중**이라는
뜻입니다. 그 통로로 아무것도 내려오지 않습니다.

즉 기기·에뮬레이터·앱 문제가 아닙니다. **FCM에 메시지가 접수되지 않았거나,
접수 단계에서 거부됐습니다.**

---

## 3. 원인 후보와 확인 방법

가능성이 높은 순서입니다.

### ① 발송 호출 자체가 없다 — 가장 흔한 경우

알림 레코드 저장까지만 구현되고 FCM 발송이 안 붙었거나,
일부 타입에만 붙어서 `participation_ack`가 빠져 있는 경우입니다.

**확인**: 발송 코드가 실제로 호출되는지 로그 한 줄 찍어보시면 즉시 판별됩니다.

### ② 앱과 다른 Firebase 프로젝트로 보내고 있다

FCM 토큰은 프로젝트에 묶여 있습니다. 다른 프로젝트 자격으로 보내면
FCM이 `SenderId mismatch`를 돌려주고, **앱에는 아무 로그도 남지 않습니다.**

앱이 등록된 프로젝트:

| 항목 | 값 |
|---|---|
| `project_id` | `octoverse-iam-dev` |
| `project_number` (Sender ID) | `716889439418` |
| 패키지명 | `kr.octoverse.iam` |

**확인**: 서버가 쓰는 서비스 계정 JSON의 `project_id`가 위와 같은지 보시면 됩니다.
다르면 둘 중 하나로 맞춰야 합니다.

### ③ 레거시 HTTP API를 쓰고 있다

`https://fcm.googleapis.com/fcm/send` + 서버 키(`AAAA...`) 방식은
**2024년에 지원이 종료**됐습니다. 지금은 404/401만 돌아옵니다.

현재 방식:
```
POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
Authorization: Bearer {서비스 계정 OAuth2 액세스 토큰}
```

**확인**: 호출하는 URL과 인증 헤더 형태를 보시면 됩니다.

### ④ 서비스 계정 권한 부족

`cloudmessaging.messages.create` 권한이 없으면 403이 옵니다.

---

## 4. 제일 먼저 해주실 것

**FCM API 호출의 응답 상태코드와 본문을 로그로 남겨주세요.**

이거 하나면 ①~④가 즉시 갈립니다.

| 로그에 찍히는 것 | 원인 |
|---|---|
| 호출 자체가 안 찍힘 | ① 발송 미연결 |
| `403` + `SenderId mismatch` | ② 프로젝트 불일치 |
| `404` 또는 legacy 엔드포인트 | ③ 레거시 API |
| `403` + `PERMISSION_DENIED` | ④ 권한 부족 |
| `200` + `name: projects/.../messages/...` | 발송은 성공 → 다시 알려주세요 |

마지막 경우라면 서버는 정상이고 저희 쪽이나 FCM 전달 구간을 더 파야 합니다.

---

## 5. 직접 쏴보실 토큰

아래는 실제 살아 있는 Android 기기 토큰입니다. `curl`로 바로 테스트하실 수 있습니다.

```
dLOz1C_-RRulw5a62r6MuM:APA91bH4dW9JdRGXYz8Gge12AHUIhacmN7UAr5V_vun6jeg5MHjChAjE_QYnNiLDBGJWkVx9IJJfyxbucbJPprgLyzrR0A9fa-0gW4pIYQKw12TX_kSl1hY
```

⚠️ 에뮬레이터가 살아 있는 동안만 유효합니다. 만료되면 알려주세요, 새로 뽑아드립니다.

보내실 때 페이로드는 계약 문서 §2 형식대로 부탁드립니다:

```json
{
  "message": {
    "token": "<위 토큰>",
    "notification": {
      "title": "참가 신청이 접수됐어요",
      "body": "AI 빌더 네트워킹 나이트"
    },
    "data": {
      "notification_id": "test-0001",
      "type": "participation_ack",
      "channel_slug": "ai-ed1ee9"
    }
  }
}
```

`data`의 값은 **전부 문자열**이어야 합니다. 숫자를 넣으면 FCM이 400을 돌려줍니다.

---

## 참고 — 앱은 이 상태입니다

푸시가 오기만 하면 아래가 동작하도록 구현·검증까지 끝나 있습니다.

- 백그라운드·종료 상태 → OS가 표시 (`notification` 블록 필요)
- 포그라운드 → 앱이 직접 배너를 그림 + 알림함 배지 갱신
- 알림 탭 → `data.type`으로 분기
  - 모임 관련 5종 → `data.channel_slug`의 모임 상세
  - 명함 교환 3종 → 명함함
  - `welcome`·알 수 없는 타입·`channel_slug` 누락 → 알림함 (크래시 없음)
- 로그아웃 → `DELETE /users/me/devices/{token}` 후 기기 토큰 폐기
