import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/typography.dart';

import 'iam_icon.dart';

/// 아바타 크기 프리셋. 숫자를 직접 주려면 [IamAvatar.size]를 쓴다.
enum IamAvatarSize {
  sm(32),
  md(44),
  lg(56),
  xl(88);

  const IamAvatarSize(this.px);
  final double px;
}

/// IamAvatar — IAM DS · core
///
/// 원형 아바타. 사진 → 없으면 이름 첫 글자 → 그래도 없으면 사람 아이콘.
/// `IAM_web/src/components/ds/core/Avatar.tsx` 이식.
///
/// ⚠️ **K2(본인인증 제외)**: [verified]는 계약상 prop으로 유지하되
///    인증 도트를 **렌더하지 않는다**. 웹과 동일한 규칙이다.
class IamAvatar extends StatelessWidget {
  const IamAvatar({
    super.key,
    this.src,
    this.name = '',
    this.preset = IamAvatarSize.md,
    this.size,
    this.verified = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  /// 프로필 이미지 URL.
  final String? src;

  /// 이니셜·시맨틱 라벨용 이름.
  final String name;

  final IamAvatarSize preset;

  /// px 직접 지정. 주면 [preset]보다 우선한다.
  final double? size;

  /// K2 — 받기만 하고 그리지 않는다.
  final bool verified;

  /// 강조용 오버라이드(주최자 카드의 코랄 링 등). 없으면 기본 토큰.
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  double get _px => size ?? preset.px;

  @override
  Widget build(BuildContext context) {
    final px = _px;
    final trimmed = name.trim();
    // 웹 `name.charAt(0)`과 동일하게 첫 코드 단위를 쓴다(한글은 BMP라 안전).
    final initial = trimmed.isEmpty ? '' : trimmed.substring(0, 1);
    final hasImage = src != null && src!.isNotEmpty;

    final bg =
        backgroundColor ??
        (hasImage ? AppColors.surfaceSunken : AppColors.iris100);
    final fg = foregroundColor ?? AppColors.iris700;

    return Semantics(
      label: name.isEmpty ? null : name,
      image: hasImage,
      child: Container(
        width: px,
        height: px,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor ?? AppColors.borderSubtle),
        ),
        alignment: Alignment.center,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: src!,
                width: px,
                height: px,
                fit: BoxFit.cover,
                // 이미지가 깨지면 이니셜 폴백으로 되돌린다 — 빈 원보다 낫다.
                errorWidget: (_, __, ___) => _fallback(initial, px, fg),
                placeholder: (_, __) => const SizedBox.shrink(),
              )
            : _fallback(initial, px, fg),
      ),
    );
  }

  Widget _fallback(String initial, double px, Color fg) {
    if (initial.isEmpty) {
      return IamIcon(IamIconName.user, size: px * 0.5, color: fg);
    }
    return Text(
      initial,
      style: AppTypography.body.copyWith(
        // 웹과 동일 비율 — 지름의 40%.
        fontSize: px * 0.4,
        height: 1,
        fontWeight: AppTypography.semibold,
        color: fg,
      ),
    );
  }
}
