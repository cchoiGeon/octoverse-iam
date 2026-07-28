import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'me_settings_controller.dart';

/// 14 설정.
///
/// 라우트   : AppRoutes.meSettings
/// 웹 대응  : `IAM_web/src/app/(app)/me/settings/page.tsx`
/// 디자인   : Figma `3.UI` node 137:722
class MeSettingsView extends GetView<MeSettingsController> {
  const MeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SafeArea(
        child: Column(
          children: [
            IamAppHeader(title: '설정', onBack: Get.back),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppDimens.space10),
                children: [
                  _sectionLabel('알림'),
                  Obx(
                    () => IamListItem(
                      title: '이메일 알림',
                      description: '리마인더·모임 소식을 이메일로 받아요',
                      showChevron: false,
                      trailing: IamToggle(
                        checked: controller.emailEnabled.value,
                        enabled: !controller.isLoading.value,
                        onChanged: controller.setEmailEnabled,
                        semanticLabel: '이메일 알림',
                      ),
                    ),
                  ),
                  _sectionLabel('약관·정책'),
                  IamListItem(title: '서비스 이용약관', onTap: controller.openTerms),
                  IamListItem(
                    title: '개인정보 처리방침',
                    onTap: controller.openPrivacy,
                  ),
                  _sectionLabel('계정'),
                  Obx(
                    () => IamListItem(
                      title: '로그인 계정',
                      value: controller.email,
                      showChevron: false,
                    ),
                  ),
                  IamListItem(
                    icon: IamIconName.logOut,
                    title: '로그아웃',
                    showChevron: false,
                    onTap: () => _confirmLogout(context),
                  ),
                  IamListItem(
                    title: '회원 탈퇴',
                    danger: true,
                    showChevron: false,
                    onTap: () => _confirmWithdraw(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.gutterMobile),
                    child: Text(
                      '진행 중인 주최 모임이 있으면 탈퇴할 수 없어요. 모임을 종료한 뒤 다시 시도해 주세요.',
                      style: AppTypography.caption.copyWith(
                        height: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppDimens.gutterMobile,
      AppDimens.space5,
      AppDimens.gutterMobile,
      AppDimens.space2,
    ),
    child: Text(
      text,
      style: AppTypography.caption.copyWith(
        height: 1.3,
        fontWeight: AppTypography.semibold,
        letterSpacing: 0.26,
        color: AppColors.textTertiary,
      ),
    ),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await IamDialog.show(
      context,
      title: '로그아웃할까요?',
      description: '다시 로그인하면 이어서 이용할 수 있어요.',
      confirmText: '로그아웃',
    );
    if (ok) await controller.logout();
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final ok = await IamDialog.show(
      context,
      title: '정말 탈퇴할까요?',
      description: '프로필·참가 내역·찜이 모두 사라져요. 되돌릴 수 없어요.',
      confirmText: '탈퇴하기',
      tone: IamDialogTone.danger,
    );
    if (ok) await controller.withdraw();
  }
}
