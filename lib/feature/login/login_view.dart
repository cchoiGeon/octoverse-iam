import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'login_controller.dart';

/// 01 랜딩 — 카카오 로그인.
///
/// 라우트   : AppRoutes.login
/// 웹 대응  : `IAM_web/src/app/(app)/page.tsx`의 `<Landing>`
/// 디자인   : Figma `3.UI` node 87:7 (01 랜딩)
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          // Figma: linear-gradient(160deg, iris-50, surface-page 60%)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.iris50, AppColors.surfacePage],
            stops: [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutterMobile,
              AppDimens.space8,
              AppDimens.gutterMobile,
              AppDimens.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _hero()),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IAM',
          style: AppTypography.displayL.copyWith(
            color: AppColors.primary,
            height: 1.1,
            letterSpacing: -0.96,
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          '만나기 전에,\n이미 통하는 사이.',
          style: AppTypography.title1.copyWith(height: 1.3),
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          '오프라인 모임 직전, 참가자들을 미리 만나보고\n현장에서 통하는 사람을 찾아보세요.',
          style: AppTypography.bodyL.copyWith(
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Obx(
      () => Column(
        children: [
          IamKakaoLoginButton(
            label: IamKakaoLabel.start,
            enabled: !controller.isBusy,
            onPressed: controller.loginWithKakao,
          ),
        ],
      ),
    );
  }
}
