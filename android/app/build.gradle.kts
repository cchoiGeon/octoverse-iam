import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
    namespace = "kr.octoverse.iam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "kr.octoverse.iam"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["kakaoNativeKey"] = kakaoNativeKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
