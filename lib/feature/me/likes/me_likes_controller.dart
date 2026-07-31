import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 12 찜 관리 — 내가 찜한 / 나를 찜한.
///
/// 라우트   : AppRoutes.meLikes
/// 웹 대응  : `IAM_web/src/app/(app)/me/likes/page.tsx`
class MeLikesController extends GetxController {
  MeLikesController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  static const tabs = ['내가 찜한', '나를 찜한'];

  final RxInt tab = 0.obs;
  final RxList<MyLikeRow> sent = <MyLikeRow>[].obs;
  final RxList<MyLikeRow> received = <MyLikeRow>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// 찜 취소가 진행 중인 행 id. 같은 행을 연타로 두 번 지우지 않게 막는다.
  final RxSet<String> unliking = <String>{}.obs;

  List<MyLikeRow> get current => tab.value == 0 ? sent : received;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _api.myLikes(direction: 'sent'),
        _api.myLikes(direction: 'received'),
      ]);
      sent.value = results[0].content;
      received.value = results[1].content;
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// 찜 취소 — 되돌릴 수 있는 액션이라 낙관적으로 먼저 지우고 실패하면 되살린다.
  ///
  /// 찜은 "모임 안에서" 걸리므로 취소도 그 모임의 slug로 나간다
  /// (`DELETE /channels/{slug}/likes/{toUserId}`).
  ///
  /// 진행 중인 행은 [unliking]에 담아 연타를 막는다.
  Future<void> unlike(MyLikeRow row) async {
    if (unliking.contains(row.id)) return;

    final index = sent.indexWhere((r) => r.id == row.id);
    if (index < 0) return;

    unliking.add(row.id);
    sent.removeAt(index);
    try {
      await _api.unlike(row.channel.slug, row.user.id);
      _toast.success('${row.user.nickname}님 찜을 취소했어요.');
    } catch (_) {
      // 지웠던 자리에 그대로 되돌린다 — 목록 순서가 흔들리면 뭘 눌렀는지 잃는다.
      sent.insert(index.clamp(0, sent.length), row);
      _toast.error('찜 취소에 실패했어요. 다시 시도해 주세요.');
    } finally {
      unliking.remove(row.id);
    }
  }

  /// 찜은 모임 안에서만 의미가 있다 — 그 모임의 프로필 상세로 보낸다.
  void openProfile(MyLikeRow row) =>
      Get.toNamed(AppRoutes.eventPeopleDetailOf(row.channel.slug, row.user.id));
}
