import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import 'package:iam/common/constants/defines.dart';

export 'enums/enums.dart';
export 'models/models.dart';

/// 로컬 저장소 래퍼 + 모델·enum barrel.
/// Pickle의 `data/data_manager.dart`와 같은 자리다.
///
/// 웹에서는 localStorage가 이 역할을 했다:
///   `iam.session`(토큰) · `iam.reference`(참조 캐시) · `iam.notif.read`(읽음)
abstract final class Storage {
  static GetStorage get _box => GetStorage();

  /// `main()`에서 `runApp` 전에 반드시 호출한다.
  static Future<void> init() => GetStorage.init();

  static T? read<T>(String key) => _box.read<T>(key);
  static Future<void> write(String key, dynamic value) =>
      _box.write(key, value);
  static Future<void> remove(String key) => _box.remove(key);
  static Future<void> clear() => _box.erase();

  // ── 세션 토큰 ─────────────────────────────────────────────
  static String? get accessToken => read<String>(kStorageAccessToken);
  static String? get refreshToken => read<String>(kStorageRefreshToken);

  static Future<void> saveSession({
    required String access,
    required String refresh,
  }) async {
    await write(kStorageAccessToken, access);
    await write(kStorageRefreshToken, refresh);
  }

  static Future<void> clearSession() async {
    await remove(kStorageAccessToken);
    await remove(kStorageRefreshToken);
  }

  static bool get hasSession => (accessToken ?? refreshToken) != null;

  // ── 읽은 알림 id 집합 ─────────────────────────────────────
  // 서버 응답에 is_read가 없고 읽음 API도 없어 로컬로 보관한다.
  // 이게 없으면 재조회할 때마다 미읽음으로 환원돼 벨 배지를 영구히 못 지운다.
  // ⚠️ 서버에 is_read/읽음 API가 생기면 이 블록을 지우고 서버 동기화로 교체한다.

  static Set<String> get readNotificationIds {
    final raw = read<String>(kStorageNotificationRead);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> addReadNotifications(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final next = readNotificationIds..addAll(ids);
    await write(kStorageNotificationRead, jsonEncode(next.toList()));
  }
}
