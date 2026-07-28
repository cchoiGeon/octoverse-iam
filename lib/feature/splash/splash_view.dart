import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

import 'splash_controller.dart';

/// 부팅 화면 — 로고만 보여주고 세션 확인이 끝나면 스스로 빠진다.
///
/// 라우트   : AppRoutes.splash
/// 디자인   : Figma `3.UI` 01 랜딩의 로고 영역을 재사용.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.iris50, AppColors.surfacePage],
            stops: [0, 0.6],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'IAM',
                style: AppTypography.display.copyWith(
                  color: AppColors.primary,
                  letterSpacing: -0.84,
                ),
              ),
              const SizedBox(height: AppDimens.space3),
              Text(
                '만나기 전에, 이미 통하는 사이',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
