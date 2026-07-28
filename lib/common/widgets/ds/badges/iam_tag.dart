import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

/// 태그 톤.
enum IamTagTone { neutral, primary, accent }

/// 태그 크기. sm 24 · md 28 (px 높이)
enum IamTagSize { sm, md }

/// IamTag — IAM DS · badges
///
/// 관심사·카테고리 태그. **읽기 전용 칩**이다.
/// 선택 가능한 필터가 필요하면 `IamFilterChip`을 쓴다.
///
/// `IAM_web/src/components/ds/badges/Tag.tsx` 이식.
/// (웹의 tone `default`는 Dart 예약어와 겹쳐 `neutral`로 바꿨다.)
class IamTag extends StatelessWidget {
  const IamTag(
    this.label, {
    super.key,
    this.tone = IamTagTone.neutral,
    this.size = IamTagSize.md,
  });

  final String label;
  final IamTagTone tone;
  final IamTagSize size;

  @override
  Widget build(BuildContext context) {
    final sm = size == IamTagSize.sm;
    final (bg, fg) = switch (tone) {
      IamTagTone.neutral => (AppColors.surfaceSunken, AppColors.textSecondary),
      IamTagTone.primary => (AppColors.iris50, AppColors.iris700),
      IamTagTone.accent => (AppColors.coral50, AppColors.coral700),
    };

    // ⚠️ `alignment`를 주면 Container가 가능한 최대 너비까지 늘어난다
    //    (Align이 최대 크기를 차지하기 때문). Wrap 안에서 태그가 한 줄을
    //    통째로 먹어 세로로 쌓이는 원인이었다.
    //    높이는 세로 패딩으로 만든다 — 웹의 height 24/28 + line-height 1과 동일:
    //    sm (24-12)/2 = 6 · md (28-13)/2 = 7.5
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sm ? 9 : 11,
        vertical: sm ? 6 : 7.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: (sm ? AppTypography.label : AppTypography.caption).copyWith(
          height: 1,
          fontWeight: AppTypography.medium,
          letterSpacing: (sm ? 12 : 13) * -0.01,
          color: fg,
        ),
      ),
    );
  }
}
