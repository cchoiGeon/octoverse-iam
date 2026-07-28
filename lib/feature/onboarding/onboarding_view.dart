import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'onboarding_controller.dart';
import 'widgets/step_history.dart';
import 'widgets/step_profile.dart';
import 'widgets/step_terms.dart';

/// 02·03 프로필 작성 — 3스텝 셸.
///
/// 라우트   : AppRoutes.onboarding
/// 웹 대응  : `IAM_web/src/app/(auth)/onboarding/page.tsx`
/// 디자인   : Figma `3.UI` v3 (239:702 · 239:752)
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      // 키보드가 올라와도 폼이 가려지지 않게 본문이 밀려 올라간다.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutterMobile,
                  AppDimens.space6,
                  AppDimens.gutterMobile,
                  AppDimens.space6,
                ),
                child: IamStepper(
                  steps: OnboardingController.steps,
                  current: controller.step.value,
                ),
              ),
              Expanded(child: _stepBody(controller.step.value)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(int step) => switch (step) {
    0 => const OnboardingStepProfile(),
    1 => const OnboardingStepHistory(),
    _ => const OnboardingStepTerms(),
  };
}

/// 스텝 공용 프레임 — 제목·설명 + 스크롤 본문 + 하단 액션.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    required this.actions,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutterMobile,
              0,
              AppDimens.gutterMobile,
              AppDimens.space6,
            ),
            children: [
              _Header(title: title, description: description),
              const SizedBox(height: AppDimens.space5),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutterMobile,
            AppDimens.space3,
            AppDimens.gutterMobile,
            AppDimens.space6,
          ),
          child: actions,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.title2.copyWith(height: 1.3)),
        const SizedBox(height: AppDimens.space2),
        Text(
          description,
          style: AppTypography.body.copyWith(
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
