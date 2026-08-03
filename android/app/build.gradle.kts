import java.util.Properties

plugins {
    id("com.android.application")
    // google-services 는 android application 플러그인 뒤에 와야 한다.
    // 앞에 두면 android {} 확장이 아직 없어서 설정을 못 읽는다.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리즈 서명 정보. android/key.properties 에서 읽는다(저장소 밖, gitignore 대상).
//
// 이 파일이 없는 환경도 정상이다 — 서명 키가 없는 개발자/CI 는 아래에서
// 디버그 키로 폴백한다. 없다고 빌드를 깨뜨리지 않는다.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val keystoreProperties =
    Properties().apply {
        if (hasReleaseSigning) keystorePropertiesFile.inputStream().use { load(it) }
    }

// 카카오 네이티브 앱 키.
//
// 매니페스트의 리다이렉트 스킴(`kakao{키}://oauth`)은 **빌드 시점에 확정**돼야 해서
// `--dart-define` 으로는 못 넣는다(그건 Dart 코드에만 들어간다). gradle이 읽어
// manifestPlaceholder 로 주입한다.
//
// ⚠️ local.properties 에 두면 안 된다. Flutter gradle 플러그인이 매 빌드마다
//    그 파일을 다시 써서 직접 추가한 줄이 조용히 지워진다.
//
// 우선순위: 환경변수 → android/kakao.properties (둘 다 저장소 밖).
// 없으면 빈 문자열 → 스킴이 죽지만, 그 경우 Dart 쪽도 kUseTestLogin 으로
// 폴백하므로 이 액티비티를 탈 일이 없다.
val kakaoNativeKey: String =
    System.getenv("KAKAO_NATIVE_KEY")
        ?: Properties().apply {
            val f = rootProject.file("kakao.properties")
            if (f.exists()) f.inputStream().use { load(it) }
        }.getProperty("kakao.nativeKey")
        ?: ""

android {
    namespace = "com.octoverse.iam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 가 API 26+ 전용 API(java.time 등)를
        // minSdk 24까지 폴리필로 쓰기 위해 desugaring을 요구한다.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.octoverse.iam"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["kakaoNativeKey"] = kakaoNativeKey
    }

    signingConfigs {
        // key.properties 가 있을 때만 만든다. 없는데 만들면 storeFile 이 null 이라
        // 설정 단계에서 바로 터진다.
        if (hasReleaseSigning) {
            create("release") {
                fun required(key: String): String =
                    keystoreProperties.getProperty(key)
                        ?: error("android/key.properties 에 $key 가 없다")

                // storeFile 경로는 이 모듈(android/app) 기준으로 풀린다.
                storeFile = file(required("storeFile"))
                storePassword = required("storePassword")
                keyAlias = required("keyAlias")
                keyPassword = required("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // key.properties 가 없으면 디버그 키로 폴백해서 `flutter run --release` 는
            // 계속 돈다. 스토어에 올릴 빌드는 반드시 key.properties 가 있는 환경에서
            // 뽑아야 한다 — 디버그 서명 AAB 는 Play Console 이 거부한다.
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // isCoreLibraryDesugaringEnabled 가 요구하는 폴리필 라이브러리.
    // 버전은 임의로 고른 게 아니다 — flutter_local_notifications 22.2.0 이
    // 자기 android/build.gradle 과 README 에서 그대로 pin 해 둔 값을 따른다.
    // 플러그인을 올릴 때는 이 값도 같이 재확인한다
    // (~/.pub-cache/hosted/pub.dev/flutter_local_notifications-<ver>/android/build.gradle).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
