import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/core/route/app_pages.dart';

import 'me_profile_controller.dart';

/// 10 내 프로필 편집.
///
/// 라우트   : AppRoutes.meProfile
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/page.tsx`
/// 디자인   : Figma `3.UI` v3-03 (239:795)
class MeProfileView extends GetView<MeProfileController> {
  const MeProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '프로필 편집', onBack: Get.back),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isLoading.value
            ? const SizedBox.shrink()
            : IamBottomCTABar(
                children: [
                  Expanded(
                    child: IamButton(
                      label: '저장',
                      size: IamButtonSize.lg,
                      block: true,
                      loading: controller.isSaving.value,
                      onPressed: controller.save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: Column(
          children: [
            IamSkeleton.circle(width: 120),
            SizedBox(height: AppDimens.space5),
            IamSkeleton.block(height: 52),
            SizedBox(height: AppDimens.space4),
            IamSkeleton.block(height: 52),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space5,
        AppDimens.gutterMobile,
        AppDimens.space10,
      ),
      children: [
        Obx(
          () => IamImageUpload(
            preview: controller.newPhoto.value != null
                ? FileImage(controller.newPhoto.value!)
                : (controller.photoUrl.value != null
                          ? NetworkImage(controller.photoUrl.value!)
                          : null)
                      as ImageProvider?,
            onPick: controller.pickPhoto,
            onRemove: controller.removePhoto,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamInput(
            controller: controller.nickname,
            label: '닉네임',
            required: true,
            placeholder: '표시될 이름',
            maxLength: 30,
            error: controller.nicknameError.value,
            onChanged: (_) => controller.nicknameError.value = null,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        IamInput(
          controller: controller.oneLiner,
          label: '한 줄 소개',
          placeholder: '나를 한 문장으로',
          maxLength: kMaxOneLiner,
        ),
        const SizedBox(height: AppDimens.space5),
        IamTextarea(
          controller: controller.introduction,
          label: '자기소개',
          placeholder: '관심사·하는 일·만나고 싶은 사람 등',
          maxLength: kMaxIntroduction,
          rows: 5,
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '관심사',
            options: [
              for (final t in controller.interestOptions)
                IamTagOption('${t.id}', t.label),
            ],
            value: controller.interestIds.toList(),
            onChanged: (v) => controller.interestIds.value = v,
            max: kMaxInterests,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '보유 스킬',
            options: [
              for (final s in controller.skillOptions)
                IamTagOption(s.name, s.name),
            ],
            value: controller.skills.toList(),
            onChanged: (v) => controller.skills.value = v,
            max: kMaxSkills,
          ),
        ),
        const SizedBox(height: AppDimens.space6),
        _readOnlySection(),
      ],
    );
  }

  /// 경력·이력·링크는 여기서 개수만 보여준다.
  /// 편집은 전용 화면이 필요하고(서브 라우트), 그건 아직 스텁이다.
  Widget _readOnlySection() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '경력 · 이력 · 링크',
            style: AppTypography.bodyS.copyWith(
              height: 1.3,
              fontWeight: AppTypography.semibold,
            ),
          ),
          const SizedBox(height: AppDimens.space2),
          Text(
            '경력 ${controller.careers.length}개 · 이력 ${controller.recordCount}개 · 링크 ${controller.links.length}개',
            style: AppTypography.bodyS.copyWith(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space3),
          IamButton(
            label: '＋ 경력 추가',
            variant: IamButtonVariant.ghost,
            size: IamButtonSize.sm,
            block: true,
            onPressed: () => Get.toNamed(AppRoutes.meProfileCareer),
          ),
          const SizedBox(height: AppDimens.space2),
          IamButton(
            label: '＋ 이력 추가',
            variant: IamButtonVariant.ghost,
            size: IamButtonSize.sm,
            block: true,
            onPressed: () => Get.toNamed(AppRoutes.meProfileRecord),
          ),
          const SizedBox(height: AppDimens.space2),
          IamButton(
            label: '＋ 링크 추가',
            variant: IamButtonVariant.ghost,
            size: IamButtonSize.sm,
            block: true,
            onPressed: () => Get.toNamed(AppRoutes.meProfileLink),
          ),
        ],
      ),
    );
  }
}
