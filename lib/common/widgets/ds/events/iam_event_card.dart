import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/badges/iam_status_badge.dart';
import 'package:iam/common/widgets/ds/badges/iam_tag.dart';
import 'package:iam/common/widgets/ds/core/iam_avatar.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';
import 'package:iam/data/enums/channel_enums.dart';

/// IamEventCard — IAM DS · events
///
/// 모임 카드. 커버(200) 위에 상태 배지와 주최/참여 오버레이를 얹고,
/// 본문에 제목·일시·장소·설명·관심사를 둔다.
///
/// `IAM_web/src/components/ds/events/EventCard.tsx` 이식.
class IamEventCard extends StatelessWidget {
  const IamEventCard({
    super.key,
    required this.title,
    required this.date,
    required this.place,
    required this.phase,
    this.description,
    this.cover,
    this.joined = 0,
    this.capacity = 0,
    this.host,
    this.hostAvatar,
    this.interests = const [],
    this.onTap,
  });

  final String title;

  /// 이미 포맷된 일시 문자열 — `DateTimeUtils.eventRange()` 결과.
  final String date;
  final String place;

  /// 시각·정원으로 계산된 상태. 서버 status가 아니다.
  final ChannelPhase phase;

  final String? description;
  final String? cover;
  final int joined;
  final int capacity;
  final String? host;
  final String? hostAvatar;

  /// 관심사 라벨. 최대 3개만 노출한다.
  final List<String> interests;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tags = interests.take(3).toList();
    final meta = [date, place].where((s) => s.isNotEmpty).join('  ·  ');

    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            boxShadow: AppShadows.elev1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_cover(), _body(tags, meta)],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover != null && cover!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const _CoverFallback(),
              placeholder: (_, __) => const _CoverFallback(),
            )
          else
            const _CoverFallback(),

          // 더 이상 신청을 받지 않는 상태는 흐리게. 진행 중은 오히려 강조한다.
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

          // 하단 스크림 + 주최자·참여 인원(소셜 프루프).
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
                children: [
                  if (host != null) ...[
                    IamAvatar(src: hostAvatar, name: host!, size: 28),
                    const SizedBox(width: AppDimens.space2),
                    Expanded(
                      child: Text(
                        host!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          height: 1.2,
                          fontWeight: AppTypography.medium,
                          color: AppColors.gray0,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const IamIcon(
                    IamIconName.users,
                    size: 14,
                    color: AppColors.gray0,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    capacity > 0 ? '$joined/$capacity명' : '$joined명',
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

  Widget _body(List<String> tags, String meta) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimens.space3,
        left: AppDimens.space4,
        right: AppDimens.space4,
        bottom: AppDimens.space4,
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
}

/// 커버 이미지가 없거나 로드 실패했을 때의 인디고 그라데이션.
class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

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
