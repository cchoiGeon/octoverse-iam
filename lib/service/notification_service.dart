import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';

import 'auth_service.dart';

/// 인앱 알림 피드 + 미읽음 카운트.
/// `IAM_web/src/lib/services/notifications.ts` 이식.
///
/// ⚠️ **읽음 상태는 로컬 보관이다.**
/// 실서버 알림 응답에 `is_read`가 없고 읽음 엔드포인트도 없어서, 읽은 id를
/// `Storage`에 쌓아두고 조회 결과에 머지한다. 이게 없으면 재조회할 때마다
/// 미읽음으로 환원돼 벨 배지를 영구히 못 지운다.
/// 서버에 `is_read`/읽음 API가 생기면 이 머지를 걷어내고 서버 동기화로 바꾼다.
class NotificationService extends GetxService {
  NotificationService(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  final RxList<NotificationRow> items = <NotificationRow>[].obs;
  final RxBool isLoading = false.obs;

  /// 헤더 벨 배지 숫자.
  int get unreadCount => items.where((n) => !n.isRead).length;

  /// 로그인 상태에서만 조회한다(비로그인 401 호출을 막는다).
  Future<void> load({int size = 30}) async {
    if (!_auth.isAuthenticated) {
      items.clear();
      return;
    }
    isLoading.value = true;
    try {
      final page = await _api.notifications(size: size);
      // 서버가 새로 추가한 타입은 그릴 방법이 없으니 뺀다. 목록 전체를
      // 버리지 않는 게 요점이다 — 나머지 알림은 그대로 보여야 한다.
      final known = page.content.where(
        (n) => n.type != NotificationType.unknown,
      );
      items.value = _mergeRead(known.toList());
    } catch (e) {
      // 화면은 막지 않는다(알림은 보조 기능). 다만 조용히 삼키면 목록이 왜
      // 비었는지 알 길이 없어진다 — 실제로 그것 때문에 파싱 실패를 한참
      // 못 찾았다.
      if (kDebugMode) debugPrint('[NotificationService] 알림 조회 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 서버 `is_read`와 로컬 읽음 집합을 합친다.
  List<NotificationRow> _mergeRead(List<NotificationRow> rows) {
    final read = Storage.readNotificationIds;
    if (read.isEmpty) return rows;
    return rows
        .map(
          (n) => n.isRead || read.contains(n.id) ? n.copyWith(isRead: true) : n,
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    await Storage.addReadNotifications([id]);
    items.value = items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  Future<void> markAllRead() async {
    await Storage.addReadNotifications(items.map((n) => n.id));
    items.value = items.map((n) => n.copyWith(isRead: true)).toList();
  }

  /// 로그아웃 시 호출 — 다음 유저에게 이전 알림이 보이면 안 된다.
  void clear() => items.clear();
}
