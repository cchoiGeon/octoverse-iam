/// 서비스 barrel — `import 'package:iam/service/services.dart';`
///
/// 웹의 `IAM_web/src/lib/services/*`(Provider 조합)에 대응한다.
/// 전부 `GetxService`라 `Get.delete()`로 지워지지 않는 전역 싱글턴이다.
///
/// | 웹 | 여기 |
/// |---|---|
/// | `AuthProvider` / `useAuth` | `AuthService` |
/// | `ReferenceProvider` / `useReference` | `ReferenceService` |
/// | `ToastProvider` / `useToast` | `ToastService` |
/// | `useNotifications` / `useUnreadCount` | `NotificationService` |
/// | `messageForError` / `errorCode` | `ApiError`(core/network) |
/// | `RequireAuth` / `RequireOrganizer` | `RouteGuard`(GetX middleware) |
/// | (웹에 없음 — 앱 전용) | `PushService` |
library;

export 'auth_service.dart';
export 'notification_service.dart';
export 'push_service.dart';
export 'reference_service.dart';
export 'toast_service.dart';
