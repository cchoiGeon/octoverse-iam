import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/data/data_manager.dart';

/// Dio 설정 — 인증 헤더 첨부 + 401 재시도.
/// `IAM_web/src/lib/api/client.ts` 이식.
///
/// **웹과의 차이**: 웹은 HttpOnly 쿠키 세션(`credentials:'include'`)이라
/// 브라우저가 토큰을 자동으로 실어 보냈다. 앱은 쿠키 저장소가 없으므로
/// Bearer 헤더를 직접 붙이고 토큰을 `Storage`에 보관한다.
abstract final class DioConfig {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: kApiBase,
        connectTimeout: kConnectTimeout,
        receiveTimeout: kReceiveTimeout,
        headers: {'Accept': 'application/json'},
        // validateStatus는 기본값(2xx만 성공)을 그대로 둔다.
        // 4xx를 성공으로 통과시키면 Retrofit이 에러 본문을 성공 모델로
        // 파싱하려다 엉뚱한 타입 에러를 낸다 → 에러는 onError에서만 다룬다.
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));

    assert(() {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: false,
          error: true,
          compact: true,
        ),
      );
      return true;
    }());

    return dio;
  }
}

/// 인터셉터가 바깥 세상에 알리는 콜백 모음.
///
/// 인터셉터가 라우팅을 직접 알면 순환 의존이 생기고 테스트도 어려워진다.
/// `main.dart`가 여기에 "로그인 화면으로 보내기"를 꽂아준다.
abstract final class AuthInterceptorHooks {
  /// refresh까지 실패해 세션이 끊겼을 때 호출된다.
  static void Function()? onSessionExpired;
}

/// 액세스 토큰 첨부 + 401 분기.
///
/// 401 원인을 `error.code`로 구분한다(웹 규칙 그대로):
///   · `UNAUTHORIZED`  = 토큰 무효/위조/탈퇴 → 즉시 로그아웃
///   · 그 외(`TOKEN_EXPIRED` 등) = access 만료 → refresh 1회 후 재시도
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;

  /// 동시 401이 refresh를 여러 번 호출하지 않게 하는 single-flight 잠금.
  /// 웹 `refreshTokens()`의 `refreshing` 프라미스와 같은 역할이다.
  static Future<bool>? _refreshing;

  /// 재시도 여부 표시 키. 웹의 `_retry` 플래그에 대응한다.
  static const _retriedKey = '__iam_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = Storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final opts = err.requestOptions;

    // 이미 한 번 재시도한 요청이면 더 시도하지 않는다(무한 루프 방지).
    if (opts.extra[_retriedKey] == true) {
      await _signOut();
      handler.next(err);
      return;
    }

    // refresh 호출 자체가 401이면 재귀를 끊는다.
    if (opts.path.contains('/auth/refresh')) {
      await _signOut();
      handler.next(err);
      return;
    }

    final data = err.response?.data;
    final code = data is Map && data['error'] is Map
        ? (data['error'] as Map)['code']?.toString()
        : null;

    // 위조·탈퇴 케이스는 refresh를 타면 안 된다 — 바로 로그아웃.
    if (code == 'UNAUTHORIZED') {
      await _signOut();
      handler.next(err);
      return;
    }

    if (!await _refresh()) {
      await _signOut();
      handler.next(err);
      return;
    }

    try {
      opts.extra[_retriedKey] = true;
      opts.headers['Authorization'] = 'Bearer ${Storage.accessToken}';
      handler.resolve(await _dio.fetch(opts));
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }

  /// refresh 호출. 동시에 여러 401이 나도 실제 호출은 한 번만 나간다.
  Future<bool> _refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refresh = Storage.refreshToken;
    if (refresh == null) return false;
    try {
      // 인터셉터를 타지 않는 별도 Dio — 재귀 401을 피한다.
      final plain = Dio(BaseOptions(baseUrl: kApiBase));
      final res = await plain.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final body = res.data;
      final access = body?['access_token'] as String?;
      final next = body?['refresh_token'] as String?;
      if (access == null || next == null) return false;
      await Storage.saveSession(access: access, refresh: next);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signOut() async {
    await Storage.clearSession();
    AuthInterceptorHooks.onSessionExpired?.call();
  }
}
