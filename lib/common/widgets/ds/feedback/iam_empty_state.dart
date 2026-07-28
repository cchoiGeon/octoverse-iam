import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// 빈 상태 톤.
enum IamEmptyStateTone {
  /// 차분한 회색 — 빈 목록·에러
  neutral,

  /// 성공 톤 — 체크인 완료 등
  success,
}

/// IamEmptyState — IAM DS · feedback
///
/// 빈 목록·에러·완료를 한 컴포넌트로 다룬다.
/// 아이콘 + 제목 + (설명) + (액션). 차분하고 안심되는 톤.
///
/// `IAM_web/src/components/ds/feedback/EmptyState.tsx` 이식.
/// (웹의 tone `default`는 Dart 관례상 `neutral`로 바꿨다.)
class IamEmptyState extends StatelessWidget {
  const IamEmptyState({
    super.key,
    required this.title,
    this.icon = IamIconName.inbox,
    this.description,
    this.action,
    this.tone = IamEmptyStateTone.neutral,
    this.padding,
  });

  final String title;
  final IamIconName icon;
  final String? description;

  /// 보통 `IamButton` — "다시 시도" · "모임 탐색" 등.
  final Widget? action;

  final IamEmptyStateTone tone;

  /// 기본 여백을 줄이고 싶을 때(리스트 안에 끼워 넣는 경우 등).
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isSuccess = tone == IamEmptyStateTone.success;
    final circleBg = isSuccess
        ? AppColors.statusOpenBg
        : AppColors.surfaceSunken;
    final iconColor = isSuccess
        ? AppColors.statusOpenFg
        : AppColors.textTertiary;

    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            vertical: AppDimens.space10,
            horizontal: AppDimens.space6,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: AppDimens.space2),
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: IamIcon(icon, size: 30, color: iconColor),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.title3.copyWith(
              height: 1.4,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppDimens.space2),
            ConstrainedBox(
              // 한 줄이 너무 길어지면 읽기 어렵다 — 웹과 같은 280px 상한.
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppDimens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}
