import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'link_form_controller.dart';

/// v3-06 외부 링크 추가.
///
/// 라우트   : AppRoutes.meProfileLink
/// 디자인   : Figma `3.UI` v3-06 (239:983)
class MeProfileLinkView extends GetView<MeProfileLinkController> {
  const MeProfileLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '링크 추가', onBack: Get.back),
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
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '링크 종류',
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
                            for (final t in LinkType.values)
                              IamFilterChip(
                                label: t.label,
                                selected: controller.type.value == t,
                                size: IamFilterChipSize.sm,
                                onTap: () => controller.type.value = t,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.space5),
                  Obx(
                    () => IamInput(
                      controller: controller.url,
                      label: 'URL',
                      required: true,
                      placeholder: 'https://',
                      keyboardType: TextInputType.url,
                      error: controller.urlError.value,
                      onChanged: (_) => controller.urlError.value = null,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space5),
                  IamInput(
                    controller: controller.label,
                    label: '라벨 (선택)',
                    placeholder: '비우면 도메인이 자동 표시돼요',
                    maxLength: 30,
                  ),
                  const SizedBox(height: AppDimens.space5),
                  const IamInfoBanner(message: '외부 링크는 최대 5개까지 추가할 수 있어요.'),
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
}
