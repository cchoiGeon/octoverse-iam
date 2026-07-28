import 'package:intl/intl.dart';

/// 날짜·시간 표시 — `IAM_web/src/lib/format/datetime.ts` 이식.
///
/// 서버 타임스탬프는 ISO-8601 UTC("…Z")다. 표시는 항상 KST(Asia/Seoul)로 한다.
///
/// ⚠️ `timezone` 패키지를 쓰지 않고 UTC+9 고정 오프셋으로 계산한다.
///    한국은 서머타임이 없어 안전하고, 기기 타임존과 무관하게 결과가 같다.
abstract final class DateTimeUtils {
  static const _kstOffset = Duration(hours: 9);

  /// ISO 문자열 → KST 기준 DateTime(내부 계산용).
  static DateTime toKst(String iso) =>
      DateTime.parse(iso).toUtc().add(_kstOffset);

  /// "6월 20일 (금)"
  static String eventDate(String iso) =>
      DateFormat('M월 d일 (E)', 'ko_KR').format(toKst(iso));

  /// "오후 7:00"
  ///
  /// ⚠️ intl에 맡기지 않고 직접 조립한다. intl 0.20의 `ko` 로케일은 AM/PM을
  ///    **"AM"/"PM"** 으로 정의한다(CLDR 42에서 한국어 dayPeriod가 바뀌었다).
  ///    `DateFormat('a h:mm','ko_KR')` 도 `DateFormat.jm('ko_KR')` 도 "PM 7:18"이
  ///    나온다. 웹(브라우저 ICU)과 Figma는 "오후 7:00" 이라 그대로 두면 갈린다.
  static String time(String iso) {
    final d = toKst(iso);
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.hour < 12 ? '오전' : '오후'} $hour12:$minute';
  }

  /// "2026.06.20"
  static String ymd(String iso) => DateFormat('yyyy.MM.dd').format(toKst(iso));

  /// "6월 20일 (금) · 오후 7:00–9:00"
  /// 하루 안에 끝나면 날짜를 접고, 넘어가면 종료 날짜까지 쓴다.
  static String eventRange(String startIso, String endIso) {
    final start = toKst(startIso);
    final end = toKst(endIso);
    final day = DateFormat('M월 d일 (E)', 'ko_KR').format(start);
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '$day · ${time(startIso)}–${time(endIso)}';
    }
    return '$day ${time(startIso)} – ${eventDate(endIso)} ${time(endIso)}';
  }

  /// 입력 폼에서 고른 KST 시각 → 서버로 보낼 UTC ISO 문자열.
  /// `eventRange`와 정확히 대칭이라 왕복해도 값이 어긋나지 않는다.
  static String toUtcIso(DateTime kstLocal) {
    final utc = DateTime.utc(
      kstLocal.year,
      kstLocal.month,
      kstLocal.day,
      kstLocal.hour,
      kstLocal.minute,
    ).subtract(_kstOffset);
    return utc.toIso8601String();
  }

  /// "방금 전 · N분 전 · N시간 전 · N일 전 · 날짜" (알림 목록용)
  static String relative(String iso) {
    final diff = DateTime.now().toUtc().difference(DateTime.parse(iso).toUtc());
    final min = diff.inMinutes;
    if (min < 1) return '방금 전';
    if (min < 60) return '$min분 전';
    final hr = diff.inHours;
    if (hr < 24) return '$hr시간 전';
    final day = diff.inDays;
    if (day < 7) return '$day일 전';
    return ymd(iso);
  }

  /// 남은 시간 → "1시간 5분 후" / "5분 32초 후" (주최자 체크인 카운트다운)
  static String until(Duration d) {
    final total = d.isNegative ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return '$h시간 $m분 후';
    if (m > 0) return '$m분 $s초 후';
    return '$s초 후';
  }
}
