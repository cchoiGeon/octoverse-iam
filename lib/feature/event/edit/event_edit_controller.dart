import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/event/shared/channel_form_controller.dart';
import 'package:iam/service/services.dart';

/// 06b 모임 수정.
///
/// 라우트   : AppRoutes.eventEdit
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/edit/page.tsx`
class EventEditController extends GetxController with ChannelFormMixin {
  EventEditController(this.api, this.reference, this.toast, this._auth);

  @override
  final ApiClient api;
  @override
  final ReferenceService reference;
  @override
  final ToastService toast;

  final AuthService _auth;

  late final String slug = Get.parameters['slug'] ?? '';

  final RxBool isLoading = true.obs;

  /// 주최자 판정 — 서버도 403을 주지만 화면에서도 막는다.
  /// 미들웨어에서는 채널을 모르므로 여기서 한다(웹 `<RequireOrganizer>` 대응).
  final RxBool isOrganizer = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    disposeFormControllers();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final c = await api.channel(slug);
      isOrganizer.value = _auth.isOrganizer(c.organizer.id);
      title.text = c.title;
      description.text = c.description;
      location.text = c.location;
      capacity.text = '${c.capacity}';
      coverUrl.value = c.coverImageUrl;
      category.value = c.category;
      interestIds.value = c.interests.map((t) => '${t.id}').toList();
      isPublic.value = c.isPublic;
      startAt.value = DateTimeUtils.toKst(c.startAt);
      endAt.value = DateTimeUtils.toKst(c.endAt);
    } catch (e) {
      toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void goDetail() => Get.offNamed(AppRoutes.eventDetailOf(slug));

  Future<void> submit() async {
    if (isSubmitting.value || !validate()) return;
    isSubmitting.value = true;
    try {
      final cover = await resolveCoverUrl();
      final r = buildRequest(cover);
      await api.updateChannel(
        slug,
        ChannelUpdateRequest(
          title: r.title,
          description: r.description,
          location: r.location,
          category: r.category,
          startAt: r.startAt,
          endAt: r.endAt,
          capacity: r.capacity,
          isPublic: r.isPublic,
          coverImageUrl: r.coverImageUrl,
          interestTagIds: r.interestTagIds,
        ),
      );
      // 닫고 나서 토스트 — 순서를 뒤집으면 GetX가 라우트 대신 스낵바를 닫는다.
      toast.backThen('변경 사항을 저장했어요.', result: true);
    } catch (e) {
      // 정원을 현재 승인 인원보다 줄이면 CAPACITY_BELOW_ACCEPTED 가 온다.
      toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
