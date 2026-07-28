import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';
import 'package:iam/service/services.dart';

/// v3-06 외부 링크 추가.
///
/// 라우트   : AppRoutes.meProfileLink
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/link/LinkForm.tsx`
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
      final ok = await _saver.save((p) {
        final existing = p.links ?? const <LinkItem>[];
        if (existing.length >= kMaxLinks) {
          _toast.error('외부 링크는 최대 $kMaxLinks개까지 추가할 수 있어요.');
          throw StateError('link limit');
        }
        return ProfileItemSaver.carryOver(
          p,
          links: [
            ...existing,
            LinkItem(
              type: type.value,
              url: normalized,
              label: label.text.trim().isEmpty ? null : label.text.trim(),
            ),
          ],
        );
      });
      if (ok) Get.back(result: true);
    } catch (_) {
      // 한도 초과는 위에서 이미 안내했다.
    } finally {
      isSaving.value = false;
    }
  }
}
