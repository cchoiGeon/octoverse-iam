import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';
import 'package:iam/service/services.dart';

/// v3-06 외부 링크 추가·수정.
///
/// 라우트   : AppRoutes.meProfileLink
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/link/LinkForm.tsx`
///
/// 수정 모드는 `Get.arguments`([LinkEditArgs])로 들어온다. 없으면 추가 모드.
class MeProfileLinkController extends GetxController {
  MeProfileLinkController(ApiClient api, AuthService auth, this._toast)
    : _saver = ProfileItemSaver(api, auth, _toast);

  final ProfileItemSaver _saver;
  final ToastService _toast;

  final url = TextEditingController();
  final label = TextEditingController();

  final Rx<LinkType> type = LinkType.sns.obs;
  final RxBool isSaving = false.obs;
  final RxnString urlError = RxnString();

  /// 수정 중인 항목의 위치. null이면 추가 모드.
  int? editIndex;

  bool get isEdit => editIndex != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is! LinkEditArgs) return;
    editIndex = arg.index;
    url.text = arg.item.url;
    label.text = arg.item.label ?? '';
    type.value = arg.item.type;
  }

  @override
  void onClose() {
    url.dispose();
    label.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (isSaving.value) return;
    final raw = url.text.trim();
    if (raw.isEmpty) {
      urlError.value = 'URL을 입력해 주세요.';
      return;
    }
    // http(s) 가 빠진 주소는 열리지 않는다 — 저장 전에 보완한다.
    final normalized = raw.startsWith('http') ? raw : 'https://$raw';

    isSaving.value = true;
    try {
      await _saver.save((p) {
        final existing = p.links ?? const <LinkItem>[];
        // 한도는 **추가할 때만** 본다 — 수정은 개수를 늘리지 않는다.
        if (!isEdit && existing.length >= kMaxLinks) {
          _toast.error('외부 링크는 최대 $kMaxLinks개까지 추가할 수 있어요.');
          throw StateError('link limit');
        }
        return ProfileItemSaver.carryOver(
          p,
          links: ProfileItemSaver.upsert(
            existing,
            LinkItem(
              type: type.value,
              url: normalized,
              label: label.text.trim().isEmpty ? null : label.text.trim(),
            ),
            editIndex,
          ),
        );
      });
      // 성공하면 saver가 화면을 닫고 토스트를 띄운다(순서 주의 — backThen 주석).
    } catch (_) {
      // 한도 초과는 위에서 이미 안내했다.
    } finally {
      isSaving.value = false;
    }
  }

  /// 수정 모드에서만 호출된다. 확인 다이얼로그는 화면이 띄운다.
  Future<void> delete() async {
    final index = editIndex;
    if (isSaving.value || index == null) return;
    isSaving.value = true;
    try {
      await _saver.save(
        (p) => ProfileItemSaver.carryOver(
          p,
          links: ProfileItemSaver.removeAt(p.links, index),
        ),
        message: '링크를 삭제했어요.',
      );
      // 성공하면 saver가 화면을 닫고 토스트를 띄운다(순서 주의 — backThen 주석).
    } finally {
      isSaving.value = false;
    }
  }
}
