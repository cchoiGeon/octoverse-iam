import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'record_form_controller.dart';

/// v3-05 이력 추가 — 학력·자격증·수상·어학.
///
/// 라우트   : AppRoutes.meProfileRecord
/// 디자인   : Figma `3.UI` v3-05 (239:940)
class MeProfileRecordView extends GetView<MeProfileRecordController> {
  const MeProfileRecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(
              title: controller.isEdit ? '이력 수정' : '이력 추가',
              onBack: Get.back,
            ),
            Expanded(
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutterMobile,
                    AppDimens.space5,
                    AppDimens.gutterMobile,
                    AppDimens.space10,
                  ),
                  children: [
                    // 수정 중에는 종류가 곧 "어느 배열이냐"라서 바꿀 수 없다.
                    if (!controller.isEdit) ...[
                      _kindPicker(),
                      const SizedBox(height: AppDimens.space5),
                    ],
                    ..._fields(),
                    if (controller.error.value != null) ...[
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        controller.error.value!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error700,
                        ),
                      ),
                    ],
                    if (controller.isEdit) ...[
                      const SizedBox(height: AppDimens.space6),
                      IamButton(
                        label: '${controller.kind.value.label} 삭제',
                        variant: IamButtonVariant.ghost,
                        block: true,
                        enabled: !controller.isSaving.value,
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ],
                ),
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

  Widget _kindPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
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
            for (final k in RecordKind.values)
              IamFilterChip(
                label: k.label,
                selected: controller.kind.value == k,
                size: IamFilterChipSize.sm,
                onTap: () => controller.setKind(k),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _fields() => switch (controller.kind.value) {
    RecordKind.education => [
      IamInput(
        controller: controller.school,
        label: '학교명',
        placeholder: '예: 한국대학교',
      ),
      const SizedBox(height: AppDimens.space5),
      Row(
        children: [
          Expanded(
            child: IamInput(
              controller: controller.major,
              label: '전공',
              placeholder: '예: 컴퓨터공학',
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: IamInput(
              controller: controller.degree,
              label: '학위',
              placeholder: '예: 학사',
            ),
          ),
        ],
      ),
      const SizedBox(height: AppDimens.space5),
      Row(
        children: [
          Expanded(
            child: IamInput(
              controller: controller.eduStart,
              label: '시작일',
              placeholder: 'YYYY-MM',
              maxLength: 7,
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: IamInput(
              controller: controller.eduEnd,
              label: '종료일',
              placeholder: 'YYYY-MM',
              maxLength: 7,
            ),
          ),
        ],
      ),
    ],
    RecordKind.certification => [
      IamInput(
        controller: controller.certName,
        label: '자격증명',
        required: true,
        placeholder: '자격증 이름',
      ),
      const SizedBox(height: AppDimens.space5),
      IamInput(
        controller: controller.certIssuer,
        label: '발급 기관',
        placeholder: '발급 기관',
      ),
      const SizedBox(height: AppDimens.space5),
      IamInput(
        controller: controller.certDate,
        label: '취득일',
        placeholder: 'YYYY-MM',
        maxLength: 7,
      ),
    ],
    RecordKind.award => [
      IamInput(
        controller: controller.awardName,
        label: '수상명',
        required: true,
        placeholder: '수상 이름',
      ),
      const SizedBox(height: AppDimens.space5),
      IamInput(
        controller: controller.awardOrg,
        label: '수여 기관',
        placeholder: '수여 기관',
      ),
      const SizedBox(height: AppDimens.space5),
      IamInput(
        controller: controller.awardDate,
        label: '수상일',
        placeholder: 'YYYY-MM',
        maxLength: 7,
      ),
    ],
    RecordKind.language => [
      IamInput(
        controller: controller.language,
        label: '언어',
        required: true,
        placeholder: '영어·일본어·중국어 등',
      ),
      const SizedBox(height: AppDimens.space5),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수준',
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
              for (final l in LanguageLevel.values)
                IamFilterChip(
                  label: l.label,
                  selected: controller.langLevel.value == l,
                  size: IamFilterChipSize.sm,
                  onTap: () => controller.langLevel.value =
                      controller.langLevel.value == l ? null : l,
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppDimens.space5),
      IamInput(
        controller: controller.langScore,
        label: '점수·등급',
        placeholder: 'TOEIC 900 · JLPT N1 등 (선택)',
      ),
    ],
  };

  Future<void> _confirmDelete(BuildContext context) async {
    final label = controller.kind.value.label;
    final ok = await IamDialog.show(
      context,
      title: '$label을 삭제할까요?',
      description: '삭제하면 프로필에서 바로 사라져요. 되돌릴 수 없어요.',
      confirmText: '삭제',
      tone: IamDialogTone.danger,
    );
    if (ok) await controller.delete();
  }
}
