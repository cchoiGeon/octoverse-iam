import 'package:get/get.dart';

import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 13 알림 센터.
///
/// 라우트   : AppRoutes.meNotifications
/// 웹 대응  : `IAM_web/src/app/(app)/me/notifications/page.tsx`
///
/// 읽음 상태는 서버에 저장할 곳이 없어 로컬 보관이다
/// (`NotificationService` 주석 참고).
class MeNotificationsController extends GetxController {
  MeNotificationsController(this._notifications);

  final NotificationService _notifications;

  RxList<NotificationRow> get items => _notifications.items;
  RxBool get isLoading => _notifications.isLoading;
  int get unreadCount => _notifications.unreadCount;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() => _notifications.load();

  Future<void> markAllRead() => _notifications.markAllRead();

  /// 알림을 열면 읽음 처리하고, 모임 알림이면 해당 모임으로 보낸다.
  Future<void> open(NotificationRow n) async {
    await _notifications.markRead(n.id);
    final slug = n.channel?.slug;
    if (slug != null) Get.toNamed(AppRoutes.eventDetailOf(slug));
  }
}
