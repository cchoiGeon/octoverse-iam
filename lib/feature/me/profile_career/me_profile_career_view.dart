import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'career_form_controller.dart';

/// v3-04 경력 추가.
///
/// 라우트   : AppRoutes.meProfileCareer
/// 디자인   : Figma `3.UI` v3-04 (239:892)
class MeProfileCareerView extends GetView<MeProfileCareerController> {
  const MeProfileCareerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(
              title: controller.isEdit ? '경력 수정' : '경력 추가',
              onBack: Get.back,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutterMobile,
                  AppDimens.space5,
                  AppDimens.gutterMobile,
                  AppDimens.space10,
                ),
                children: [
                  Obx(
                    () => IamInput(
                      controller: controller.company,
                      label: '회사명',
                      required: true,
                      placeholder: '예: 토스',
                      maxLength: 50,
                      error: controller.companyError.value,
                      onChanged: (_) => controller.companyError.value = null,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space5),
                  IamInput(
                    controller: controller.title,
                    label: '직책·역할',
                    placeholder: '예: 프로덕트 디자이너',
                    maxLength: 50,
                  ),
                  const SizedBox(height: AppDimens.space5),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => IamInput(
                            controller: controller.startYm,
                            label: '시작일',
                            required: true,
                            placeholder: 'YYYY-MM',
                            maxLength: 7,
                            error: controller.startError.value,
                            onChanged: (_) =>
                                controller.startError.value = null,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space3),
                      Expanded(
                        child: Obx(
                          () => IamInput(
                            controller: controller.endYm,
                            label: '종료일',
                            placeholder: 'YYYY-MM',
                            maxLength: 7,
                            enabled: !controller.isCurrent.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Obx(
                    () => IamListItem(
                      title: '현재 재직 중',
                      description: '켜면 종료일이 비활성화돼요',
                      showChevron: false,
                      trailing: IamToggle(
                        checked: controller.isCurrent.value,
                        onChanged: (v) => controller.isCurrent.value = v,
                        semanticLabel: '현재 재직 중',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space5),
                  Obx(() => _jobCategory()),
                  const SizedBox(height: AppDimens.space5),
                  IamTextarea(
                    controller: controller.description,
                    label: '업무 설명·성과',
                    placeholder: '담당 업무와 주요 성과를 적어 주세요',
                    maxLength: 300,
                    rows: 4,
                  ),
                  if (controller.isEdit) ...[
                    const SizedBox(height: AppDimens.space6),
                    Obx(
                      () => IamButton(
                        label: '경력 삭제',
                        variant: IamButtonVariant.ghost,
                        block: true,
                        enabled: !controller.isSaving.value,
                        onPressed: () => _confirmDelete(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => IamBottomCTABar(
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

  Widget _jobCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '직무 카테고리',
          style: AppTypography.bodyS.copyWith(
            height: 1.3,
            fontWeight: AppTypography.semibold,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final c in JobCategory.values)
              IamFilterChip(
                label: c.label,
                selected: controller.jobCategory.value == c,
                size: IamFilterChipSize.sm,
                onTap: () => controller.jobCategory.value =
                    controller.jobCategory.value == c ? null : c,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await IamDialog.show(
      context,
      title: '경력을 삭제할까요?',
      description: '삭제하면 프로필에서 바로 사라져요. 되돌릴 수 없어요.',
      confirmText: '삭제',
      tone: IamDialogTone.danger,
    );
    if (ok) await controller.delete();
  }
}
