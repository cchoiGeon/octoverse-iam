import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/badges/iam_tag.dart';
import 'package:iam/common/widgets/ds/core/iam_avatar.dart';
import 'package:iam/common/widgets/ds/social/iam_like_button.dart';

/// IamProfileCard — IAM DS · social
///
/// 참가자 리스트의 기본 단위. 사진 · 닉네임 · 한 줄 소개 · 관심사 · 찜.
/// `IAM_web/src/components/ds/social/ProfileCard.tsx` 이식.
///
/// ⚠️ K2 — 인증 표식은 렌더하지 않는다.
class IamProfileCard extends StatelessWidget {
  const IamProfileCard({
    super.key,
    required this.name,
    this.photo,
    this.headline,
    this.tags = const [],
    this.badge,
    this.liked = false,
    this.onLike,
    this.onTap,
  });

  final String name;
  final String? photo;

  /// 한 줄 소개.
  final String? headline;

  /// 관심사. 3개까지 보이고 나머지는 "+N".
  final List<String> tags;

  /// 이름 옆 배지(체크인 "참석" 등).
  final Widget? badge;

  final bool liked;

  /// null이면 찜 버튼을 아예 그리지 않는다(본인·자격 미달 카드).
  final ValueChanged<bool>? onLike;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            boxShadow: AppShadows.elev1,
          ),
          child: Row(
            children: [
              // K2: verified 미전달
              IamAvatar(src: photo, name: name, preset: IamAvatarSize.lg),
              const SizedBox(width: AppDimens.space3),
              Expanded(child: _body()),
              if (onLike != null) ...[
                const SizedBox(width: AppDimens.space3),
                IamLikeButton(liked: liked, onChanged: onLike),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final shown = tags.take(3).toList();
    final rest = tags.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title3.copyWith(
                  height: 1.2,
                  fontWeight: AppTypography.bold,
                  letterSpacing: -0.18,
                ),
              ),
            ),
            if (badge != null) ...[const SizedBox(width: 5), badge!],
          ],
        ),
        if (headline != null && headline!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            headline!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyS.copyWith(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < shown.length; i++)
                IamTag(
                  shown[i],
                  size: IamTagSize.sm,
                  // 첫 태그만 인디고로 강조 — 가장 대표적인 관심사.
                  tone: i == 0 ? IamTagTone.primary : IamTagTone.neutral,
                ),
              if (rest > 0) IamTag('+$rest', size: IamTagSize.sm),
            ],
          ),
        ],
      ],
    );
  }
}
