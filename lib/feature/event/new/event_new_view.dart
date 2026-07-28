import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/feature/event/shared/channel_form_body.dart';

import 'event_new_controller.dart';

/// 06 모임 생성.
///
/// 라우트   : AppRoutes.eventNew
/// 웹 대응  : `IAM_web/src/app/(app)/event/new/page.tsx`
/// 디자인   : Figma `3.UI` node 101:116 · 326:1432
class EventNewView extends GetView<EventNewController> {
  const EventNewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '모임 만들기', onBack: Get.back),
            Expanded(child: ChannelFormBody(controller: controller)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => IamBottomCTABar(
          children: [
            Expanded(
              child: IamButton(
                label: '모임 만들기',
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
