# 네이티브 설정 — 최초 1회

이 저장소에는 `android/` · `ios/` 폴더가 없다. Flutter가 생성하는 파일이라 손으로 만들면
버전이 어긋난다. 아래 순서대로 한 번만 하면 된다.

---

## 0. 플랫폼 폴더 생성

```bash
cd IAM_flutter

# ⚠️ lib/main.dart 를 덮어쓸 수 있다. 먼저 백업.
cp -r lib ../.iam_lib_backup

flutter create --platforms=android,ios --org com.octoverse .

# 덮어쓴 게 있는지 확인하고, 있으면 백업에서 되돌린다.
diff -r ../.iam_lib_backup lib
```

`--org com.octoverse` → 패키지명 `com.octoverse.iam`. 이미 정해진 값이 있으면 그걸 쓴다.

---

## 1. 폰트

`assets/fonts/`에 Pretendard 4종을 넣는다. **없으면 빌드가 실패한다**
(`unable to locate asset entry`).

| 파일명 | weight |
|---|---|
| `Pretendard-Regular.otf` | 400 |
| `Pretendard-Medium.otf` | 500 |
| `Pretendard-SemiBold.otf` | 600 |
| `Pretendard-Bold.otf` | 700 |

> 웹(`IAM_web`)은 가변 폰트 하나(`PretendardVariable.woff2`)를 쓰지만,
> Flutter는 가변 폰트 지원이 플랫폼별로 고르지 않아 정적 4종을 쓴다.

---

## 2. Android

### `android/app/build.gradle`

```gradle
android {
    defaultConfig {
        minSdk = 21          // 카카오 SDK · mobile_scanner 요구 최소값
    }
}
```

### `android/app/src/main/AndroidManifest.xml`

`<manifest>` 바로 아래:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />

<!-- Android 11+ 패키지 가시성 — 없으면 카카오톡 설치 여부를 못 읽어
     항상 계정(웹뷰) 로그인으로 빠진다. -->
<queries>
    <package android:name="com.kakao.talk" />
</queries>
```

`<application>` 안:

```xml
<!-- 카카오 로그인 리다이렉트 수신 -->
<activity
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- ⚠️ {NATIVE_APP_KEY}를 실제 카카오 네이티브 앱 키로 바꾼다.
             예: android:scheme="kakao1a2b3c4d..." -->
        <data android:scheme="kakao{NATIVE_APP_KEY}" android:host="oauth" />
    </intent-filter>
</activity>
```

---

## 3. iOS

### `ios/Runner/Info.plist`

```xml
<!-- 카카오 로그인 리다이렉트 -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- ⚠️ 실제 네이티브 앱 키로 교체 -->
      <string>kakao{NATIVE_APP_KEY}</string>
    </array>
  </dict>
</array>

<!-- 카카오톡 앱 실행 가능 여부 조회 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
</array>

<!-- 권한 안내 문구 — 심사에서 문구가 비어 있으면 반려된다 -->
<key>NSCameraUsageDescription</key>
<string>모임 참가 QR을 스캔하기 위해 카메라를 사용해요.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>프로필 사진과 명함 이미지를 올리기 위해 사진에 접근해요.</string>
```

### `ios/Podfile`

```ruby
platform :ios, '13.0'
```

---

## 4. 카카오 콘솔

[developers.kakao.com](https://developers.kakao.com) → 내 애플리케이션에서:

1. **네이티브 앱 키** 복사 → 아래 실행 명령의 `KAKAO_NATIVE_KEY`
2. **플랫폼** → Android(패키지명 + 키 해시) · iOS(번들 ID) 등록
3. **카카오 로그인** 활성화
4. **OIDC 활성화** ⚠️ — 이게 꺼져 있으면 `id_token`이 null로 와서
   로그인이 "카카오 OIDC가 꺼져 있어…" 에러로 실패한다
5. **동의 항목** → 닉네임 · 이메일(필수)

---

## 4-1. Firebase 콘솔 (푸시)

FCM 푸시를 쓰려면 별도 설정이 필요하다 → [`docs/firebase-setup-android.md`](docs/firebase-setup-android.md)

`android/app/google-services.json`은 이미 저장소에 커밋돼 있어서, 그냥 클론한
경우라면 아래 콘솔 작업 없이도 빌드·실행이 된다(이 파일이 없으면 Gradle 빌드가
바로 실패하고, `main()`의 `await Firebase.initializeApp()`도 죽는다 — "나중에
해도 되는" 설정이 아니다). 이 문서의 콘솔 단계가 실제로 필요해지는 시점은
**다른 Firebase 프로젝트로 새로 연결할 때**(예: 서버가 다른 프로젝트를 쓰게
바뀌었거나, 이 앱을 포크해 별도 프로젝트로 배포할 때)뿐이다.

---

## 5. 실행

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze

flutter run \
  --dart-define=API_BASE=https://dev-api.octoverse.kr/iam/v1 \
  --dart-define=KAKAO_NATIVE_KEY=<네이티브 앱 키> \
  --dart-define=WEB_ORIGIN=https://iam.octoverse.kr
```

**`KAKAO_NATIVE_KEY`는 생략할 수 없다.** 비어 있으면 `KakaoSdk.init`을 건너뛰어
랜딩의 카카오 버튼이 SDK 호출에서 실패한다 — 진입 경로가 이것 하나뿐이라 앱을 못 쓴다.
예전에 있던 개발용 로그인(`POST /auth/test/login`) 폴백은 인증 우회라 제거했다.

---

## 확인 순서

| 단계 | 기대 결과 |
|---|---|
| 앱 실행 | 스플래시(IAM 로고) 0.6초 |
| 세션 없음 | 랜딩으로 이동 |
| 카카오 로그인 — 신규 계정 | 서버에 계정 생성 → 온보딩(3스텝)으로 이동 |
| 카카오 로그인 — 기존 계정 | 홈으로 이동 → **모임 카드 목록이 보이면 서버 연동 성공** |
| 목록 아래로 스크롤 | 다음 페이지 자동 로드 |
| 검색어 입력 | 400ms 후 서버 재조회 |
| 당겨서 새로고침 | 첫 페이지부터 다시 로드 |
