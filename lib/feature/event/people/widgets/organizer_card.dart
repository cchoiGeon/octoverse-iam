import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

/// 참가자 목록 최상단의 주최자 히어로 배너.
///
/// 일반 참가자 카드와 시각적으로 구분해 "이 모임을 만든 사람"을 주인공으로
/// 세운다. 코랄 그라데이션 + 큰 아바타 + 왕관 키커.
class OrganizerHeroCard extends StatelessWidget {
  const OrganizerHeroCard({
    super.key,
    required this.organizer,
    this.liked = false,
    this.onLike,
    this.onTap,
  });

  final Organizer organizer;
  final bool liked;
  final ValueChanged<bool>? onLike;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '주최자 ${organizer.nickname} 프로필 보기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceCard, AppColors.coral50],
            ),
            border: Border.all(color: AppColors.coral100),
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            boxShadow: AppShadows.elev3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _CrownGlyph(),
                  const SizedBox(width: AppDimens.space1),
                  Text(
                    '이 모임을 만든 사람',
                    style: AppTypography.caption.copyWith(
                      height: 1,
                      fontWeight: AppTypography.bold,
                      color: AppColors.coral600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space3),
              Row(
                children: [
                  // K2: verified 미전달
                  IamAvatar(
                    src: organizer.photoUrl,
                    name: organizer.nickname,
                    size: 64,
                    backgroundColor: AppColors.coral100,
                    foregroundColor: AppColors.coral700,
                    borderColor: AppColors.coral200,
                  ),
                  const SizedBox(width: AppDimens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizer.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title2.copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '모임 진행자',
                          style: AppTypography.bodyS.copyWith(
                            height: 1.4,
                            fontWeight: AppTypography.medium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onLike != null)
                    IamLikeButton(liked: liked, onChanged: onLike),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 왕관 글리프 — 아이콘 세트에 없어 인라인 path.
/// ⚠️ 인증 표식이 아니다(K2와 무관).
class _CrownGlyph extends StatelessWidget {
  const _CrownGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(15, 15), painter: _CrownPainter());
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(3 * s, 7 * s)
      ..lineTo(7.5 * s, 10.5 * s)
      ..lineTo(12 * s, 4 * s)
      ..lineTo(16.5 * s, 10.5 * s)
      ..lineTo(21 * s, 7 * s)
      ..lineTo(19.2 * s, 18 * s)
      ..lineTo(4.8 * s, 18 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.coral600);
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}
