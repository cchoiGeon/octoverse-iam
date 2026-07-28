import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/feature/event/shared/channel_form_body.dart';

import 'event_edit_controller.dart';

/// 06b 모임 수정.
///
/// 라우트   : AppRoutes.eventEdit
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/edit/page.tsx`
/// 디자인   : Figma `3.UI` node 182:517
class EventEditView extends GetView<EventEditController> {
  const EventEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '모임 수정', onBack: Get.back),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(AppDimens.gutterMobile),
                        child: Column(
                          children: [
                            IamSkeleton.block(height: 180),
                            SizedBox(height: AppDimens.space5),
                            IamSkeleton.block(height: 52),
                            SizedBox(height: AppDimens.space4),
                            IamSkeleton.block(height: 52),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppDimens.gutterMobile,
                              AppDimens.space4,
                              AppDimens.gutterMobile,
                              0,
                            ),
                            child: IamInfoBanner(
                              message: '일시·장소를 바꾸면 참가자에게 변경 알림이 가요.',
                            ),
                          ),
                          Expanded(
                            child: ChannelFormBody(controller: controller),
                          ),
                        ],
                      ),
              ),
            ),
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
                      label: '변경 사항 저장',
                      size: IamButtonSize.lg,
                      block: true,
                      loading: controller.isSubmitting.value,
                      onPressed: controller.submit,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
