import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 아이콘 이름 — 웹 `IconProps["name"]` 유니온에 대응.
///
/// `x` → `close`, `chevron-down` → `chevronDown` 처럼 Dart 관례로 바꿨다.
/// (`x`는 Dart에서 의미를 못 읽고, 하이픈은 식별자로 쓸 수 없다.)
enum IamIconName {
  heart,
  check,
  shieldCheck,
  search,
  bell,
  chevronDown,
  chevronRight,
  close,
  plus,
  camera,
  user,
  users,
  calendar,
  mapPin,
  arrowLeft,
  sliders,
  home,
  checkCircle,
  alertCircle,
  info,
  link,
  instagram,
  settings,
  briefcase,
  inbox,
  sort,
  logOut,
  moreHorizontal,
  qrCode,
  share,
  idCard,

  /// 체크인 코드(숫자 입력) — 참가 QR(qrCode)과 시각적으로 구분되는 키패드.
  keypad,
}

/// IamIcon — IAM DS · core
///
/// 라인 아이콘 세트. `IAM_web/src/components/ds/core/Icon.tsx` 이식.
/// Lucide 기하(24px · stroke 2 · round cap/join) 기반이며, path 데이터를
/// 웹 원본에서 **그대로** 옮겨 글리프가 정확히 같다.
///
/// Material Icons로 대체하지 않은 이유: 웹과 앱의 아이콘이 미묘하게 달라지면
/// 같은 제품으로 보이지 않는다. 새로 그리지 않고 원본 path를 쓴다.
class IamIcon extends StatelessWidget {
  const IamIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
  });

  final IamIconName name;
  final double size;

  /// 없으면 주변 텍스트 색을 따른다 — 웹의 `currentColor` 상속과 같은 의도.
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF15191F);

    return SvgPicture.string(
      _svg(name, resolved, strokeWidth),
      width: size,
      height: size,
    );
  }

  static String _svg(IamIconName name, Color color, double strokeWidth) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    // 원본 path 안의 fill="currentColor"(instagram 점)도 같은 색으로 치환한다.
    final body = (_paths[name] ?? '').replaceAll('currentColor', hex);
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="$hex" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">$body</svg>';
  }

  /// 웹 `Icon.tsx`의 `PATHS`를 그대로 옮긴 것.
  /// ⚠️ 아이콘을 고치면 웹·앱 양쪽을 함께 고친다.
  static const Map<IamIconName, String> _paths = {
    IamIconName.heart:
        '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
    IamIconName.check: '<path d="M20 6 9 17l-5-5"/>',
    IamIconName.shieldCheck:
        '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1Z"/>'
        '<path d="m9 12 2 2 4-4"/>',
    IamIconName.search:
        '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    IamIconName.bell:
        '<path d="M10.27 21a2 2 0 0 0 3.46 0"/>'
        '<path d="M3.26 15.33A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.67C19.41 13.92 18 12.57 18 8A6 6 0 0 0 6 8c0 4.57-1.41 5.92-2.74 7.33"/>',
    IamIconName.chevronDown: '<path d="m6 9 6 6 6-6"/>',
    IamIconName.chevronRight: '<path d="m9 18 6-6-6-6"/>',
    IamIconName.close: '<path d="M18 6 6 18M6 6l12 12"/>',
    IamIconName.plus: '<path d="M5 12h14M12 5v14"/>',
    IamIconName.camera:
        '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3Z"/>'
        '<circle cx="12" cy="13" r="3"/>',
    IamIconName.user:
        '<circle cx="12" cy="8" r="4"/><path d="M5.5 21a8.38 8.38 0 0 1 13 0"/>',
    IamIconName.users:
        '<circle cx="9" cy="8" r="3.5"/><path d="M3 21a6.5 6.5 0 0 1 12 0"/>'
        '<path d="M16 5.5a3.5 3.5 0 0 1 0 6.9M21 21a6.5 6.5 0 0 0-4.5-6.2"/>',
    IamIconName.calendar:
        '<rect x="3" y="4.5" width="18" height="17" rx="2.5"/>'
        '<path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>',
    IamIconName.mapPin:
        '<path d="M20 10c0 5-8 12-8 12s-8-7-8-12a8 8 0 0 1 16 0Z"/>'
        '<circle cx="12" cy="10" r="3"/>',
    IamIconName.arrowLeft: '<path d="M19 12H5M12 19l-7-7 7-7"/>',
    IamIconName.sliders:
        '<path d="M4 6h10M18 6h2M4 12h2M10 12h10M4 18h6M14 18h6"/>'
        '<circle cx="16" cy="6" r="2"/><circle cx="8" cy="12" r="2"/><circle cx="12" cy="18" r="2"/>',
    IamIconName.home:
        '<path d="M3 10.5 12 3l9 7.5"/>'
        '<path d="M5 9.5V20a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9.5"/>',
    IamIconName.checkCircle:
        '<circle cx="12" cy="12" r="9"/><path d="m8.5 12 2.5 2.5 4.5-5"/>',
    IamIconName.alertCircle:
        '<circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.5h.01"/>',
    IamIconName.info:
        '<circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/>',
    IamIconName.link:
        '<path d="M9 15l6-6"/><path d="M11 7l1-1a4 4 0 0 1 6 6l-1 1"/>'
        '<path d="M13 17l-1 1a4 4 0 0 1-6-6l1-1"/>',
    IamIconName.instagram:
        '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/>'
        '<circle cx="17" cy="7" r="1" fill="currentColor" stroke="none"/>',
    IamIconName.settings:
        '<circle cx="12" cy="12" r="3"/>'
        '<path d="M12 2.5v2M12 19.5v2M21.5 12h-2M4.5 12h-2M18.4 5.6l-1.4 1.4M7 17l-1.4 1.4M18.4 18.4 17 17M7 7 5.6 5.6"/>',
    IamIconName.briefcase:
        '<rect x="3" y="7.5" width="18" height="12" rx="2.5"/>'
        '<path d="M8 7.5V6a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v1.5M3 13h18"/>',
    IamIconName.inbox:
        '<path d="M3 12h5l2 3h4l2-3h5"/>'
        '<path d="M5 5.5 3 12v6a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1v-6l-2-6.5a1 1 0 0 0-1-.5H6a1 1 0 0 0-1 .5Z"/>',
    IamIconName.sort:
        '<path d="m3 8 4-4 4 4"/><path d="M7 4v16"/>'
        '<path d="m21 16-4 4-4-4"/><path d="M17 20V4"/>',
    IamIconName.logOut:
        '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>'
        '<path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
    IamIconName.moreHorizontal:
        '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
    IamIconName.qrCode:
        '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>'
        '<rect x="3" y="14" width="7" height="7" rx="1"/>'
        '<path d="M14 14h3v3M20 14h1M14 20h1M20 20h1v1"/>',
    IamIconName.share:
        '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/>'
        '<path d="m8.6 13.5 6.8 4M15.4 6.5l-6.8 4"/>',
    IamIconName.idCard:
        '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/>'
        '<path d="M6 16c.4-1.2 1.6-2 3-2s2.6.8 3 2M15 10h3M15 13.5h3"/>',
    IamIconName.keypad:
        '<circle cx="6" cy="6" r="1.4"/><circle cx="12" cy="6" r="1.4"/><circle cx="18" cy="6" r="1.4"/>'
        '<circle cx="6" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="18" cy="12" r="1.4"/>'
        '<circle cx="6" cy="18" r="1.4"/><circle cx="12" cy="18" r="1.4"/><circle cx="18" cy="18" r="1.4"/>',
  };
}
