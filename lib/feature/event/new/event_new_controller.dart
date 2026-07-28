import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/feature/event/shared/channel_form_controller.dart';
import 'package:iam/service/services.dart';

/// 06 모임 생성.
///
/// 라우트   : AppRoutes.eventNew
/// 웹 대응  : `IAM_web/src/app/(app)/event/new/page.tsx`
class EventNewController extends GetxController with ChannelFormMixin {
  EventNewController(this.api, this.reference, this.toast);

  @override
  final ApiClient api;
  @override
  final ReferenceService reference;
  @override
  final ToastService toast;

  @override
  void onClose() {
    disposeFormControllers();
    super.onClose();
  }

  Future<void> submit() async {
    if (isSubmitting.value || !validate()) return;
    isSubmitting.value = true;
    try {
      final cover = await resolveCoverUrl();
      final created = await api.createChannel(buildRequest(cover));
      toast.success('모임을 만들었어요.');
      // 생성 직후 바로 상세로 — 공유·관리로 이어지는 자연스러운 흐름.
      Get.offNamed(AppRoutes.eventDetailOf(created.slug));
    } catch (e) {
      toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
