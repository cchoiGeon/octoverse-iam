# 에뮬레이터 실행 절차

프로젝트를 열고 동작을 확인할 때까지의 순서. 최초 1회 네이티브 설정은
[`NATIVE_SETUP.md`](../NATIVE_SETUP.md)에 있고, 여기는 **매번 하는 것만** 적는다.

---

## 1. 에뮬레이터 켜기

```bash
flutter emulators                                   # 목록 확인
flutter emulators --launch Pixel_3a_API_34_extension_level_7_arm64-v8a
```

부팅이 끝나면 잡히는지 확인한다. 여기 안 보이면 `run.sh`가 macOS/Chrome으로 빠진다.

```bash
flutter devices     # android 기기가 목록에 있어야 한다
```

## 2. 의존성 받기

```bash
flutter pub get
```

## 3. 코드 생성 — 모델·ApiClient를 건드렸을 때만

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

안 돌리면 `.g.dart`가 없어 컴파일이 안 되고, 새로 넣은 필드가 조용히 무시된다.

## 4. 실행

```bash
./scripts/run.sh
```

`flutter run`을 직접 치지 않는다. 카카오 네이티브 키가 gradle(`kakao.properties`)과
Dart(`--dart-define`) 두 경로로 갈라져 있어서, 스크립트가 한 값을 양쪽에 흘려준다.
인자는 그대로 `flutter run`에 넘어간다 (예: `./scripts/run.sh -d emulator-5554`).

기본 서버는 dev(`https://dev-api.octoverse.kr/iam/v1`)다.

Android Studio·IntelliJ에서 실행 버튼으로 띄울 땐
`.idea/runConfigurations/main_dart.xml`의 `additionalArgs`가 같은 역할을 하므로 그대로 쓰면 된다.

## 5. 로컬 서버(iam-server)에 붙일 때만

```bash
# iam-server: npm run start:dev  (포트 3000, 프리픽스 /iam/v1)
API_BASE=http://10.0.2.2:3000/iam/v1 ./scripts/run.sh
```

에뮬레이터에서 호스트 PC는 `127.0.0.1`이 아니라 **`10.0.2.2`**다.

---

## 막혔을 때

| 증상 | 조치 |
|---|---|
| `run.sh`가 "⚠️ 카카오 키 없음"을 찍음 | `android/kakao.properties`에 `kakao.nativeKey=...`를 넣는다. 개발용 로그인은 제거돼서 키가 없으면 **로그인 자체가 안 된다.** |
| 카카오 인증은 끝났는데 **"계속하기" 화면에서 멈춤** | 옛 패키지(`kr.octoverse.iam`)가 기기에 남아 같은 `kakao{키}://oauth` 스킴을 물고 있어 콜백을 가로챈 것이다. 아래 "스킴 소유자 확인" 참고. |
| 서버 연결만 안 됨 (ping은 되는데 도메인 해석이 멈춤) | 에뮬레이터 DNS 문제다. `-dns-server 8.8.8.8,1.1.1.1`로 재기동한다. 앱 문제가 아니다. |
| 빌드는 되는데 화면이 안 뜸 / 이상함 | `flutter clean && flutter pub get` 후 3번부터 다시. |

### 스킴 소유자 확인 — 카카오 콜백이 안 돌아올 때

패키지명이 `kr.octoverse.iam` → `com.octoverse.iam`으로 바뀌었다. 기기에 옛 빌드가 남아 있으면
**두 앱이 같은 `kakao{키}://oauth` 스킴을 선언**해서 콜백이 엉뚱한 쪽으로 간다.
받은 쪽은 `No uri was passed to CustomTabsActivity`로 죽고, 현재 빌드는 아무 일도 일어나지 않은
것처럼 카카오 화면에 멈춰 있다. 로그를 보기 전엔 원인이 전혀 안 보인다.

```bash
adb shell pm list packages | grep octoverse       # kr.octoverse.iam 이 보이면 그게 범인
adb uninstall kr.octoverse.iam                    # 재설치로는 안 없어진다 — 다른 앱이다
```

스킴을 누가 물고 있는지 직접 확인하려면(한 줄만 나와야 정상):

```bash
adb shell pm query-activities --brief \
  -a android.intent.action.VIEW -c android.intent.category.BROWSABLE \
  -d "kakao<네이티브키>://oauth" | grep octoverse
```

`adb`가 PATH에 없으면 `~/Library/Android/sdk/platform-tools/adb`를 쓴다.

## 코드만 검증할 때

```bash
dart analyze
flutter test
```
