import 'package:dio/dio.dart';

/// 서버 에러 코드 → 한국어 메시지.
/// `IAM_web/src/lib/services/errors.ts` 1:1 이식.
///
/// UI가 서버 문구에 의존하지 않게 하는 게 목적이다.
/// 매핑에 없으면 서버 message → 그것도 없으면 일반 문구로 폴백한다.
class ApiError implements Exception {
  const ApiError(this.code, this.message, this.status);

  final String code;
  final String message;
  final int status;

  /// DioException을 우리 에러로 변환한다.
  /// 서버는 `{ error: { code, message } }` 봉투로 내려준다(REST §0).
  factory ApiError.from(Object e) {
    if (e is ApiError) return e;
    if (e is DioException) {
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        return ApiError(
          (err['code'] ?? 'UNKNOWN').toString(),
          (err['message'] ?? '').toString(),
          status,
        );
      }
      // 네트워크 단절·타임아웃 — 서버 봉투가 없다.
      final code = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'TIMEOUT',
        DioExceptionType.connectionError => 'NETWORK',
        _ => 'UNKNOWN',
      };
      return ApiError(code, '', status);
    }
    return const ApiError('UNKNOWN', '', 0);
  }

  /// 화면에 그대로 띄울 한국어 문구.
  String get displayMessage =>
      _messages[code] ?? (message.isNotEmpty ? message : _generic);

  bool get isNotFound => status == 404;
  bool get isForbidden => status == 403;

  @override
  String toString() => 'ApiError($status $code): $message';

  static const _generic = '문제가 발생했어요. 잠시 후 다시 시도해 주세요.';

  static const Map<String, String> _messages = {
    // ── 네트워크 (웹에 없던 앱 전용) ──────────────────────────
    'TIMEOUT': '응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.',
    'NETWORK': '네트워크에 연결할 수 없어요. 연결 상태를 확인해 주세요.',

    // ── auth ─────────────────────────────────────────────────
    'INVALID_PROVIDER_TOKEN': '소셜 로그인에 실패했어요. 다시 시도해 주세요.',
    'UNSUPPORTED_PROVIDER': '지원하지 않는 로그인 방식이에요.',
    'INVALID_REFRESH_TOKEN': '세션이 만료됐어요. 다시 로그인해 주세요.',
    'TOKEN_EXPIRED': '세션이 만료됐어요. 다시 로그인해 주세요.',
    'UNAUTHORIZED': '로그인이 필요해요.',
    'TERMS_NOT_AGREED': '필수 약관에 동의해 주세요.',
    'ALREADY_SIGNED_UP': '이미 가입이 완료된 계정이에요.',
    'ACTIVE_ORGANIZER': '진행 중인 주최 모임이 있어 탈퇴할 수 없어요.',

    // ── image ────────────────────────────────────────────────
    'INVALID_IMAGE_TYPE': 'JPG 또는 PNG 이미지만 올릴 수 있어요.',
    'IMAGE_TOO_LARGE': '이미지 크기는 5MB 이하여야 해요.',

    // ── profile / interests ──────────────────────────────────
    'VALIDATION_ERROR': '입력값을 확인해 주세요.',
    'PROFILE_ALREADY_EXISTS': '이미 프로필이 있어요.',
    'PROFILE_NOT_FOUND': '프로필을 찾을 수 없어요.',
    'USER_NOT_FOUND': '사용자를 찾을 수 없어요.',
    'TOO_MANY_INTERESTS': '관심사는 최대 5개까지예요.',
    'INVALID_INTEREST_TAG': '존재하지 않는 관심사예요.',

    // ── channel ──────────────────────────────────────────────
    'CHANNEL_NOT_FOUND': '모임을 찾을 수 없어요.',
    'NOT_ORGANIZER': '주최자만 할 수 있어요.',
    'CAPACITY_BELOW_ACCEPTED': '현재 승인 인원보다 정원을 적게 줄일 수 없어요.',
    'CANNOT_DELETE_ONGOING_CHANNEL': '진행 중인 모임은 삭제할 수 없어요. 종료만 가능해요.',
    'ALREADY_CLOSED': '이미 종료된 모임이에요.',

    // ── participation ────────────────────────────────────────
    'ALREADY_PARTICIPATING': '이미 신청한 모임이에요.',
    'CHANNEL_FULL': '정원이 가득 찼어요.',
    'CHANNEL_CLOSED': '종료된 모임이에요.',
    'CANNOT_JOIN_OWN_CHANNEL': '내가 주최한 모임에는 신청할 수 없어요.',
    'PARTICIPATION_NOT_FOUND': '참가 내역을 찾을 수 없어요.',
    'INVALID_STATUS_TRANSITION': '잘못된 상태 변경이에요.',

    // ── check-in ─────────────────────────────────────────────
    // ⚠️ 이 5종은 인라인 에러가 아니라 전용 화면 상태로 처리한다
    //    (체크인 화면 S4). 여기 문구는 폴백이다.
    'CHECKIN_NOT_OPEN': '아직 체크인 시간이 아니에요.',
    'CHECKIN_CLOSED': '체크인이 마감됐어요.',
    'CHECKIN_CODE_INVALID': '체크인 코드가 올바르지 않아요.',
    'NOT_PARTICIPATING': '먼저 참가 신청이 필요해요.',
    'CANNOT_CHECKIN_OWN_CHANNEL': '주최자는 자동으로 참석 처리돼요.',
    'TOO_MANY_ATTEMPTS': '시도가 너무 많아요. 잠시 후 다시 시도해 주세요.',

    // ── like ─────────────────────────────────────────────────
    'ALREADY_LIKED': '이미 찜한 상대예요.',
    'NOT_ACCEPTED_PARTICIPANT': '참가가 확정된 사람끼리만 찜할 수 있어요.',
    'CANNOT_LIKE_SELF': '자기 자신은 찜할 수 없어요.',
    'LIKE_NOT_FOUND': '찜 내역을 찾을 수 없어요.',

    // ── notification ─────────────────────────────────────────
    'NOTIFICATION_NOT_FOUND': '알림을 찾을 수 없어요.',
    'NOT_NOTIFICATION_OWNER': '본인의 알림이 아니에요.',
  };
}
