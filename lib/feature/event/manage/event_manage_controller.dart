import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 11b 참가자 관리 — 주최자 전용.
///
/// 라우트   : AppRoutes.eventManage
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/manage/page.tsx`
class EventManageController extends GetxController {
  EventManageController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  late final String slug = Get.parameters['slug'] ?? '';

  static const tabs = ['승인', '대기', '거절'];
  static const _statuses = ['accepted', 'pending', 'rejected'];

  final RxInt tab = 0.obs;
  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();
  final RxList<ParticipationRow> accepted = <ParticipationRow>[].obs;
  final RxList<ParticipationRow> pending = <ParticipationRow>[].obs;
  final RxList<ParticipationRow> rejected = <ParticipationRow>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxnString busyId = RxnString();

  /// 주최자가 아니면 화면 자체를 막는다.
  bool get isOrganizer =>
      channel.value != null && _auth.isOrganizer(channel.value!.organizer.id);

  List<ParticipationRow> get current => switch (tab.value) {
    0 => accepted,
    1 => pending,
    _ => rejected,
  };

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      channel.value = await _api.channel(slug);
      final results = await Future.wait([
        for (final s in _statuses)
          _api.participants(slug, status: s, size: 100),
      ]);
      accepted.value = results[0].content;
      pending.value = results[1].content;
      rejected.value = results[2].content;
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> decide(ParticipationRow row, bool approve) async {
    if (busyId.value != null) return;
    busyId.value = row.id;
    try {
      await _api.updateParticipation(slug, row.id, {
        'status': approve ? 'accepted' : 'rejected',
      });
      _toast.success(approve ? '참가를 승인했어요.' : '참가를 거절했어요.');
      await load();
    } catch (e) {
      _toast.showError(e);
    } finally {
      busyId.value = null;
    }
  }
}
