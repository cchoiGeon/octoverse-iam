import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/badges/iam_status_badge.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';
import 'package:iam/data/enums/channel_enums.dart';

/// IamEventDetailHeader — IAM DS · events
///
/// 상세 상단. 커버 16:9 + 상태 배지 + 제목 + 일시·장소·정원·주최 메타.
/// CTA는 `IamBottomCTABar`가 따로 담당한다.
///
/// `IAM_web/src/components/ds/events/EventDetailHeader.tsx` 이식.
class IamEventDetailHeader extends StatelessWidget {
  const IamEventDetailHeader({
    super.key,
    required this.title,
    required this.date,
    required this.place,
    required this.phase,
    this.cover,
    this.joined = 0,
    this.capacity = 0,
    this.host,
  });

  final String title;
  final String date;
  final String place;
  final ChannelPhase phase;
  final String? cover;
  final int joined;
  final int capacity;
  final String? host;

  /// 상세엔 아래 정원 행이 따로 있어 마감임박에서 남은 자리 수는 접는다.
  /// 대신 신청/정원을 배지에 붙여 한눈에 보이게 한다.
  String get _badgeLabel {
    final base = phase == ChannelPhase.soon
        ? '마감임박'
        : phase.label(joined: joined, capacity: capacity);
    final seatless = phase == ChannelPhase.full || phase == ChannelPhase.past;
    return seatless ? base : '$base · $joined/$capacity명';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: cover != null && cover!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: cover!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _CoverFallback(),
                    placeholder: (_, __) => const _CoverFallback(),
                  )
                : const _CoverFallback(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutterMobile,
              AppDimens.space5,
              AppDimens.gutterMobile,
              AppDimens.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IamStatusBadge(
                  _badgeLabel,
                  tone: IamStatusTone.fromPhase(phase),
                ),
                const SizedBox(height: AppDimens.space3),
                Text(title, style: AppTypography.title1.copyWith(height: 1.3)),
                const SizedBox(height: AppDimens.space4),
                _MetaRow(icon: IamIconName.calendar, label: '일시', value: date),
                const SizedBox(height: AppDimens.space3),
                _MetaRow(icon: IamIconName.mapPin, label: '장소', value: place),
                const SizedBox(height: AppDimens.space3),
                _MetaRow(
                  icon: IamIconName.users,
                  label: '정원',
                  value: '$joined명 신청 · 정원 $capacity명',
                ),
                if (host != null) ...[
                  const SizedBox(height: AppDimens.space3),
                  _MetaRow(icon: IamIconName.user, label: '주최', value: host!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IamIconName icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          alignment: Alignment.center,
          child: IamIcon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppDimens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  height: 1.3,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  height: 1.4,
                  fontWeight: AppTypography.semibold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
