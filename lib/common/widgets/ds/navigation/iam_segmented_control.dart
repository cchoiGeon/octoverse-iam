import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

/// IamSegmentedControl — IAM DS · navigation
///
/// 2~3개 탭 전환. 활성 세그먼트가 흰 pill로 떠오른다.
/// `IAM_web/src/components/ds/navigation/SegmentedControl.tsx` 이식 (Figma 180:56).
class IamSegmentedControl extends StatelessWidget {
  const IamSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> segments;

  /// 활성 인덱스.
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _Segment(
                    label: segments[i],
                    active: i == value,
                    onTap: enabled ? () => onChanged(i) : null,
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

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.space2,
            horizontal: AppDimens.space3,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceCard : const Color(0x00000000),
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? AppShadows.elev1 : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.bodyS.copyWith(
              height: 1.43,
              fontWeight: active ? AppTypography.medium : AppTypography.regular,
              color: active ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
