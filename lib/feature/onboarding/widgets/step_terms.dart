import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import '../onboarding_controller.dart';
import '../onboarding_view.dart';

/// Step 3 — 필수 약관 2건 + 이메일 알림 선택.
class OnboardingStepTerms extends GetView<OnboardingController> {
  const OnboardingStepTerms({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: '약관에 동의해 주세요',
      description: '서비스 이용을 위해 필수 약관 동의가 필요해요.',
      actions: Obx(
        () => Row(
          children: [
            IamButton(
              label: '이전',
              variant: IamButtonVariant.ghost,
              size: IamButtonSize.lg,
              enabled: !controller.isSubmitting.value,
              onPressed: controller.back,
            ),
            const SizedBox(width: AppDimens.space3),
            Expanded(
              child: IamButton(
                label: '가입 완료',
                size: IamButtonSize.lg,
                block: true,
                loading: controller.isSubmitting.value,
                enabled: controller.canSubmit,
                onPressed: controller.submit,
              ),
            ),
          ],
        ),
      ),
      children: [
        Obx(
          () => _ConsentRow(
            label: '(필수) 서비스 이용약관에 동의합니다',
            checked: controller.agreedTerms.value,
            onChanged: (v) => controller.agreedTerms.value = v,
          ),
        ),
        Obx(
          () => _ConsentRow(
            label: '(필수) 개인정보 처리방침에 동의합니다',
            checked: controller.agreedPrivacy.value,
            onChanged: (v) => controller.agreedPrivacy.value = v,
          ),
        ),
        const SizedBox(height: AppDimens.space3),
        Obx(
          () => _EmailOptInCard(
            checked: controller.emailOptIn.value,
            onChanged: (v) => controller.emailOptIn.value = v,
          ),
        ),
      ],
    );
  }
}

/// 행 전체가 하나의 체크박스. 내부 체크박스는 표현 전용이라
/// "버튼 안의 버튼"이 되지 않는다.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimens.touchMin),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.space3,
            horizontal: AppDimens.space2,
          ),
          child: Row(
            children: [
              IamCheckbox(checked: checked, presentational: true),
              const SizedBox(width: AppDimens.space3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    height: 1.5,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailOptInCard extends StatelessWidget {
  const _EmailOptInCard({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이메일 알림 받기',
                  style: AppTypography.body.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.semibold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(선택) 모임 소식과 리마인더를 이메일로 받아요.',
                  style: AppTypography.caption.copyWith(
                    height: 1.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          IamToggle(
            checked: checked,
            onChanged: onChanged,
            semanticLabel: '이메일 알림',
          ),
        ],
      ),
    );
  }
}
