import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';

/// 12 찜 관리 — 내가 찜한 / 나를 찜한.
///
/// 라우트   : AppRoutes.meLikes
/// 웹 대응  : `IAM_web/src/app/(app)/me/likes/page.tsx`
class MeLikesController extends GetxController {
  MeLikesController(this._api);

  final ApiClient _api;

  static const tabs = ['내가 찜한', '나를 찜한'];

  final RxInt tab = 0.obs;
  final RxList<MyLikeRow> sent = <MyLikeRow>[].obs;
  final RxList<MyLikeRow> received = <MyLikeRow>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

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

  /// 찜은 모임 안에서만 의미가 있다 — 그 모임의 프로필 상세로 보낸다.
  void openProfile(MyLikeRow row) =>
      Get.toNamed(AppRoutes.eventPeopleDetailOf(row.channel.slug, row.user.id));
}
