import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 10 내 프로필 편집.
///
/// 라우트   : AppRoutes.meProfile
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/page.tsx`
///
/// ⚠️ **PATCH는 전체 교체다.** 보낸 배열은 통째로 갈아치운다.
/// 그래서 이 화면에서 편집하지 않는 경력·이력·링크도 **원본 그대로 실어 보내야**
/// 유실되지 않는다. 웹이 `useProfileFormGate`로 막던 사고가 정확히 이것이다.
class MeProfileController extends GetxController {
  MeProfileController(this._api, this._auth, this._reference, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ReferenceService _reference;
  final ToastService _toast;

  final nickname = TextEditingController();
  final oneLiner = TextEditingController();
  final introduction = TextEditingController();

  final Rxn<File> newPhoto = Rxn<File>();
  final RxnString photoUrl = RxnString();
  final RxList<String> interestIds = <String>[].obs;
  final RxList<String> skills = <String>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString nicknameError = RxnString();

  /// 편집 대상은 아니지만 PATCH에 그대로 실어 보내야 하는 것들.
  List<CareerItem> _careers = const [];
  List<EducationItem> _educations = const [];
  List<CertificationItem> _certifications = const [];
  List<AwardItem> _awards = const [];
  List<LanguageItem> _languages = const [];
  List<LinkItem> _links = const [];

  List<CareerItem> get careers => _careers;
  List<LinkItem> get links => _links;

  /// 학력·자격·수상·어학 합계.
  int get recordCount =>
      _educations.length +
      _certifications.length +
      _awards.length +
      _languages.length;

  List<InterestTag> get interestOptions => _reference.interests;
  List<SkillTag> get skillOptions => _reference.skills;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    nickname.dispose();
    oneLiner.dispose();
    introduction.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final me = await _api.me();
      final p = me.profile;
      nickname.text = p?.nickname ?? '';
      oneLiner.text = p?.oneLiner ?? '';
      introduction.text = p?.introduction ?? '';
      photoUrl.value = p?.photoUrl;
      skills.value = p?.skills ?? const [];
      interestIds.value = me.interests.map((t) => '${t.id}').toList();

      _careers = p?.careers ?? const [];
      _educations = p?.educations ?? const [];
      _certifications = p?.certifications ?? const [];
      _awards = p?.awards ?? const [];
      _languages = p?.languages ?? const [];
      _links = p?.links ?? const [];
    } catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > kMaxImageBytes) {
        _toast.error('이미지 크기는 5MB 이하여야 해요.');
        return;
      }
      newPhoto.value = file;
    } catch (e) {
      _toast.showError(e);
    }
  }

  void removePhoto() {
    newPhoto.value = null;
    photoUrl.value = null;
  }

  Future<void> save() async {
    if (isSaving.value) return;
    if (nickname.text.trim().isEmpty) {
      nicknameError.value = '닉네임을 입력해 주세요.';
      return;
    }
    isSaving.value = true;
    try {
      var url = photoUrl.value;
      if (newPhoto.value != null) {
        url = (await _api.uploadImage(newPhoto.value!)).url;
      }

      await _api.updateProfile(
        ProfileUpdateRequest(
          nickname: nickname.text.trim(),
          oneLiner: _orNull(oneLiner.text),
          introduction: _orNull(introduction.text),
          photoUrl: url,
          skills: skills.toList(),
          interestTagIds: interestIds.map(int.parse).toList(),
          // 편집하지 않아도 반드시 함께 보낸다 — 빠지면 서버에서 지워진다.
          careers: _careers,
          educations: _educations,
          certifications: _certifications,
          awards: _awards,
          languages: _languages,
          links: _links,
        ),
      );
      await _auth.refreshMe();
      _toast.success('프로필을 저장했어요.');
      Get.back();
    } catch (e) {
      if (ApiError.from(e).code == 'VALIDATION_ERROR') {
        nicknameError.value = ApiError.from(e).displayMessage;
      }
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
