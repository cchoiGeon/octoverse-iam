import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/badges/iam_status_badge.dart';
import 'package:iam/common/widgets/ds/badges/iam_tag.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';
import 'package:iam/data/enums/channel_enums.dart';

/// IamOrganizerEventCard — IAM DS · events
///
/// 주최자용 모임 카드. `IamEventCard`와 같은 비주얼에 하단 관리 액션 행이 붙는다.
/// `IAM_web/src/components/ds/events/OrganizerEventCard.tsx` 이식.
class IamOrganizerEventCard extends StatelessWidget {
  const IamOrganizerEventCard({
    super.key,
    required this.title,
    required this.date,
    required this.place,
    required this.phase,
    required this.onManage,
    required this.onShare,
    required this.onMore,
    this.description,
    this.cover,
    this.joined = 0,
    this.capacity = 0,
    this.interests = const [],
    this.onTap,
  });

  final String title;
  final String date;
  final String place;
  final ChannelPhase phase;
  final VoidCallback onManage;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final String? description;
  final String? cover;
  final int joined;
  final int capacity;
  final List<String> interests;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: AppShadows.elev1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 카드 본체만 상세로 이동한다. 액션 행은 아래에서 따로 처리.
          GestureDetector(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_cover(), _body()],
            ),
          ),
          _actions(),
        ],
      ),
    );
  }

  Widget _cover() {
    return SizedBox(
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover != null && cover!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const _Fallback(),
              placeholder: (_, __) => const _Fallback(),
            )
          else
            const _Fallback(),
          if (phase.isDimmed) const ColoredBox(color: AppColors.overlayScrim),
          Positioned(
            top: 12,
            left: 12,
            child: IamStatusBadge.fromPhase(
              phase,
              joined: joined,
              capacity: capacity,
              size: IamStatusBadgeSize.sm,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(
                top: AppDimens.space5,
                left: AppDimens.space3,
                right: AppDimens.space3,
                bottom: AppDimens.space2,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.overlayScrimStrong, Color(0x0015191F)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const IamIcon(
                    IamIconName.users,
                    size: 14,
                    color: AppColors.gray0,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    capacity > 0 ? '$joined/$capacity명 참가' : '$joined명 참가',
                    style: AppTypography.caption.copyWith(
                      height: 1.2,
                      fontWeight: AppTypography.semibold,
                      color: AppColors.gray0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final meta = [date, place].where((s) => s.isNotEmpty).join('  ·  ');
    final tags = interests.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space3,
        horizontal: AppDimens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title3.copyWith(
              height: 1.35,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.18,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyS.copyWith(
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (description != null && description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppDimens.space2),
            Text(
              description!.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space2 + 2),
            Wrap(
              spacing: AppDimens.space2,
              runSpacing: AppDimens.space2,
              children: [for (final t in tags) IamTag(t, size: IamTagSize.sm)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space3,
        horizontal: AppDimens.space4,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          _ActionChip(
            icon: IamIconName.users,
            label: '참가자 관리',
            filled: true,
            onTap: onManage,
          ),
          const SizedBox(width: AppDimens.space2),
          _ActionChip(icon: IamIconName.share, label: '공유하기', onTap: onShare),
          const Spacer(),
          _ActionChip(
            icon: IamIconName.moreHorizontal,
            semanticLabel: '더보기',
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.onTap,
    this.label,
    this.semanticLabel,
    this.filled = false,
  });

  final IamIconName icon;
  final VoidCallback onTap;
  final String? label;
  final String? semanticLabel;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          width: label == null ? 40 : null,
          padding: label == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: AppDimens.space3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.primarySoft : const Color(0x00000000),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: filled ? null : Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IamIcon(icon, size: label == null ? 18 : 16, color: fg),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: AppTypography.label.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.medium,
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.iris400, AppColors.iris600],
      ),
    ),
  );
}
