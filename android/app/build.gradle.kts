import java.util.Properties

plugins {
    id("com.android.application")
    // google-services 는 android application 플러그인 뒤에 와야 한다.
    // 앞에 두면 android {} 확장이 아직 없어서 설정을 못 읽는다.
    id("com.google.gms.google-services")
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
        // flutter_local_notifications 가 API 26+ 전용 API(java.time 등)를
        // minSdk 24까지 폴리필로 쓰기 위해 desugaring을 요구한다.
        isCoreLibraryDesugaringEnabled = true
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

dependencies {
    // isCoreLibraryDesugaringEnabled 가 요구하는 폴리필 라이브러리.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
