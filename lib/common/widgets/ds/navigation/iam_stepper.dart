import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamStepper — IAM DS · navigation
///
/// 온보딩 가로 스텝퍼. 완료=체크 · 현재=인디고 · 사이를 진행바로 잇는다.
/// `IAM_web/src/components/ds/navigation/Stepper.tsx` 이식.
class IamStepper extends StatelessWidget {
  const IamStepper({super.key, required this.steps, required this.current});

  final List<String> steps;

  /// 0-base 현재 단계.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${steps.length}단계 중 ${current + 1}단계',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _Step(label: steps[i], index: i, current: current),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(top: 13),
                  decoration: BoxDecoration(
                    color: i < current
                        ? AppColors.primary
                        : AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.current,
  });

  final String label;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final filled = done || active;

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.surfaceSunken,
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(
                      color: AppColors.borderStrong,
                      width: AppDimens.borderWidthStrong,
                    ),
            ),
            alignment: Alignment.center,
            child: done
                ? const IamIcon(
                    IamIconName.check,
                    size: 16,
                    strokeWidth: 2.8,
                    color: AppColors.onPrimary,
                  )
                : Text(
                    '${index + 1}',
                    style: AppTypography.bodyS.copyWith(
                      height: 1,
                      fontWeight: AppTypography.bold,
                      color: filled
                          ? AppColors.onPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(
              height: 1.2,
              fontWeight: active
                  ? AppTypography.semibold
                  : AppTypography.medium,
              color: active ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
