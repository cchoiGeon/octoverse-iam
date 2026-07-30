import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/dio_configuration.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 앱 진입점 — `IAM_web/src/app/layout.tsx` + `providers.tsx` 대응.
///
/// 웹의 Provider 조합 `MSW → QueryClient → Auth → Reference → Toast`가
/// 여기서는 `Get.put(..., permanent: true)` 등록 순서로 표현된다.
/// (MSW·QueryClient에 해당하는 계층은 없다 — §README "쿼리 무효화 대응표" 참고)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 고정 — 모바일 우선(80%+) 제품이라 가로 레이아웃을 만들지 않는다.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // "6월 20일 (금)" 같은 한국어 날짜 포맷에 필요하다.
  await initializeDateFormatting('ko_KR');

  await Storage.init();

  // FCM 은 Firebase 앱이 초기화된 뒤에만 쓸 수 있다.
  // android/app/google-services.json 에서 설정을 읽으므로 인자가 없다
  // (Android 전용이라 firebase_options.dart 를 만들지 않는다).
  await Firebase.initializeApp();

  if (kKakaoNativeKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kKakaoNativeKey);
  }

  _registerGlobals();

  runApp(const IamApp());
}

/// 앱 생애주기 내내 살아있는 싱글턴.
/// 등록 순서가 곧 의존성 순서다 — ApiClient가 먼저 있어야 서비스들이 주입된다.
void _registerGlobals() {
  final api = ApiClient(DioConfig.create());
  Get.put<ApiClient>(api, permanent: true);

  final auth = Get.put(AuthService(api), permanent: true);
  Get.put(ReferenceService(api), permanent: true);
  final notifications = Get.put(NotificationService(api, auth), permanent: true);
  final push = Get.put(PushService(api, notifications), permanent: true);
  // 로그아웃 시 이 기기로 푸시가 계속 가지 않게 토큰을 뗀다.
  auth.onBeforeSignOut = push.unregister;
  Get.put(ToastService(), permanent: true);

  // 401(refresh 실패)로 세션이 끊기면 로그인 화면으로 되돌린다.
  // 인터셉터가 라우팅을 직접 알지 않도록 콜백으로만 연결한다.
  AuthInterceptorHooks.onSessionExpired = () {
    Get.find<NotificationService>().clear();
    // 세션이 끊긴 경로는 signOutLocal() 을 타지 않아 훅이 안 불린다.
    // 여기서는 Storage 가 이미 비었으므로 서버 DELETE 는 건너뛰고
    // FCM 쪽 토큰만 무효화된다(unregister() 내부의 hasSession 가드).
    unawaited(push.unregister());
    Get.offAllNamed(AppRoutes.login);
  };
}

class IamApp extends StatelessWidget {
  const IamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'IAM',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      theme: _theme,
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('ko', 'KR'),

      // ⚠️ `locale`만 주고 이걸 빠뜨리면 **날짜 선택이 통째로 터진다.**
      // 기본 델리게이트(`DefaultMaterialLocalizations`)는 영어만 제공해서,
      // 한국어 로케일로 `showDatePicker`를 열면 `DatePickerDialog`가
      // "No MaterialLocalizations found"로 죽는다. 달력·시계 같은 머티리얼
      // 위젯을 쓰는 한 이 델리게이트들이 필요하다.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],

      // 태블릿·폴더블에서 콘텐츠가 무한정 넓어지지 않게 가운데 열로 고정한다.
      // 웹의 `max-width: var(--max-content)` + `margin: 0 auto`와 같은 의도.
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppDimens.maxContent),
          child: child,
        ),
      ),
    );
  }

  static ThemeData get _theme => ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.fontFamily,
    scaffoldBackgroundColor: AppColors.surfacePage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceCard,
      error: AppColors.error600,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
