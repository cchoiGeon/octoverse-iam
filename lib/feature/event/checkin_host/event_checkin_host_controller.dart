import 'dart:async';

import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// S1 주최자 체크인 — 코드 게시.
///
/// 라우트   : AppRoutes.eventCheckinHost
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/checkin/host/page.tsx`
///
/// "테이블 위에 세워두는 화면"이다 — 멀리서 코드가 읽혀야 하고 화면이 꺼지면
/// 안 된다. 체크인엔 QR이 없다(6자리 코드만 게시).
class EventCheckinHostController extends GetxController {
  EventCheckinHostController(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  late final String slug = Get.parameters['slug'] ?? '';

  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();
  final Rxn<CheckInInfo> info = Rxn<CheckInInfo>();

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// 남은 시간 표시를 위해 1초마다 갱신되는 현재 시각.
  final Rx<DateTime> now = DateTime.now().obs;
  Timer? _ticker;

  bool get isOrganizer =>
      channel.value != null && _auth.isOrganizer(channel.value!.organizer.id);

  DateTime? get _opensAt =>
      info.value == null ? null : DateTime.tryParse(info.value!.window.opensAt);
  DateTime? get _closesAt => info.value == null
      ? null
      : DateTime.tryParse(info.value!.window.closesAt);

  bool get isOpen {
    final o = _opensAt, c = _closesAt;
    if (o == null || c == null) return false;
    final t = now.value.toUtc();
    return !t.isBefore(o) && !t.isAfter(c);
  }

  bool get isBefore {
    final o = _opensAt;
    return o != null && now.value.toUtc().isBefore(o);
  }

  Duration get untilOpen => _opensAt == null
      ? Duration.zero
      : _opensAt!.difference(now.value.toUtc());

  /// 6자리를 3-3으로 끊어 읽기 쉽게. ("417302" → "417 302")
  String get groupedCode {
    final c = info.value?.code ?? '';
    return c.length == 6 ? '${c.substring(0, 3)} ${c.substring(3)}' : c;
  }

  @override
  void onInit() {
    super.onInit();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => now.value = DateTime.now(),
    );
    load();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    // 화면을 벗어나면 반드시 꺼짐 방지를 푼다 — 안 그러면 배터리가 계속 샌다.
    WakelockPlus.disable();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      channel.value = await _api.channel(slug);
      // 주최자만 200 — 비주최자는 서버가 403을 준다.
      if (isOrganizer) {
        info.value = await _api.checkInInfo(slug);
        if (isOpen) await WakelockPlus.enable();
      }
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  void goPeople() => Get.toNamed(AppRoutes.eventPeopleOf(slug));
  void goEvent() => Get.offNamed(AppRoutes.eventDetailOf(slug));
}
