import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 내 명함 등록·수정.
///
/// 라우트   : AppRoutes.meCardsEdit
/// 웹 대응  : `IAM_web/src/app/(app)/me/cards/edit/page.tsx`
///
/// 명함은 owner당 1개인 단일 리소스다 — 등록과 수정이 같은 PUT(upsert)이다.
class MeCardsEditController extends GetxController {
  MeCardsEditController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final Rxn<File> frontFile = Rxn<File>();
  final Rxn<File> backFile = Rxn<File>();
  final RxnString frontUrl = RxnString();
  final RxnString backUrl = RxnString();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool hasCard = false.obs;

  bool get canSave => frontFile.value != null || frontUrl.value != null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final card = await _api.myBusinessCard();
      frontUrl.value = card.frontImageUrl;
      backUrl.value = card.backImageUrl;
      hasCard.value = true;
    } catch (e) {
      // 미등록(404)은 정상 — 빈 폼으로 시작한다.
      if (!ApiError.from(e).isNotFound) _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickFront() => _pick((f) => frontFile.value = f);
  Future<void> pickBack() => _pick((f) => backFile.value = f);

  Future<void> _pick(void Function(File) assign) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 90,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > kMaxImageBytes) {
        _toast.error('이미지 크기는 5MB 이하여야 해요.');
        return;
      }
      assign(file);
    } catch (e) {
      _toast.showError(e);
    }
  }

  void removeFront() {
    frontFile.value = null;
    frontUrl.value = null;
  }

  void removeBack() {
    backFile.value = null;
    backUrl.value = null;
  }

  Future<void> save() async {
    if (isSaving.value || !canSave) return;
    isSaving.value = true;
    try {
      final front = frontFile.value != null
          ? (await _api.uploadImage(frontFile.value!)).url
          : frontUrl.value!;
      final back = backFile.value != null
          ? (await _api.uploadImage(backFile.value!)).url
          : backUrl.value;

      await _api.upsertBusinessCard(
        BusinessCardUpsertRequest(frontImageUrl: front, backImageUrl: back),
      );
      _toast.success('명함을 저장했어요.');
      Get.back(result: true);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCard() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await _api.deleteBusinessCard();
      _toast.success('명함을 삭제했어요.');
      Get.back(result: true);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }
}
