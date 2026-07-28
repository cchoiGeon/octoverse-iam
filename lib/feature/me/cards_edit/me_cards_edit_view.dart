import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'me_cards_edit_controller.dart';

/// 내 명함 등록·수정.
///
/// 라우트   : AppRoutes.meCardsEdit
/// 웹 대응  : `IAM_web/src/app/(app)/me/cards/edit/page.tsx`
/// 디자인   : Figma `명함 교환` 보드 (436:2176)
class MeCardsEditView extends GetView<MeCardsEditController> {
  const MeCardsEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '내 명함', onBack: Get.back),
            Expanded(child: Obx(() => _body(context))),
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
                      enabled: controller.canSave,
                      onPressed: controller.save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: Column(
          children: [
            IamSkeleton.block(height: 180, radius: AppDimens.radiusLg),
            SizedBox(height: AppDimens.space5),
            IamSkeleton.block(height: 180, radius: AppDimens.radiusLg),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space4,
        AppDimens.gutterMobile,
        AppDimens.space10,
      ),
      children: [
        const IamInfoBanner(message: '명함은 교환을 수락한 상대에게만 공개돼요.'),
        const SizedBox(height: AppDimens.space5),
        IamImageUpload(
          label: '앞면 (필수)',
          shape: IamImageShape.card,
          placeholder: '명함 앞면 이미지',
          preview: controller.frontFile.value != null
              ? FileImage(controller.frontFile.value!)
              : (controller.frontUrl.value != null
                        ? NetworkImage(controller.frontUrl.value!)
                        : null)
                    as ImageProvider?,
          onPick: controller.pickFront,
          onRemove: controller.removeFront,
        ),
        const SizedBox(height: AppDimens.space5),
        IamImageUpload(
          label: '뒷면 (선택)',
          shape: IamImageShape.card,
          placeholder: '명함 뒷면 이미지',
          preview: controller.backFile.value != null
              ? FileImage(controller.backFile.value!)
              : (controller.backUrl.value != null
                        ? NetworkImage(controller.backUrl.value!)
                        : null)
                    as ImageProvider?,
          onPick: controller.pickBack,
          onRemove: controller.removeBack,
        ),
        if (controller.hasCard.value) ...[
          const SizedBox(height: AppDimens.space6),
          IamButton(
            label: '명함 삭제',
            variant: IamButtonVariant.ghost,
            block: true,
            enabled: !controller.isSaving.value,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await IamDialog.show(
      context,
      title: '명함을 삭제할까요?',
      description: '이미 교환한 상대에게는 더 이상 보이지 않아요.',
      confirmText: '삭제',
      tone: IamDialogTone.danger,
    );
    if (ok) await controller.deleteCard();
  }
}
