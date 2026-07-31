import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';
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

  /// 이 화면에서 직접 편집하지는 않지만 목록으로 보여주고, PATCH에도 그대로
  /// 실어 보내야 하는 것들. 항목 추가·수정 화면에서 돌아오면 [reloadItems]가 갱신한다.
  final RxList<CareerItem> careers = <CareerItem>[].obs;
  final RxList<EducationItem> educations = <EducationItem>[].obs;
  final RxList<CertificationItem> certifications = <CertificationItem>[].obs;
  final RxList<AwardItem> awards = <AwardItem>[].obs;
  final RxList<LanguageItem> languages = <LanguageItem>[].obs;
  final RxList<LinkItem> links = <LinkItem>[].obs;

  /// 학력·자격·수상·어학 합계.
  int get recordCount =>
      educations.length +
      certifications.length +
      awards.length +
      languages.length;

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

      _setItems(p);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _setItems(Profile? p) {
    careers.value = p?.careers ?? const [];
    educations.value = p?.educations ?? const [];
    certifications.value = p?.certifications ?? const [];
    awards.value = p?.awards ?? const [];
    languages.value = p?.languages ?? const [];
    links.value = p?.links ?? const [];
  }

  /// 항목 추가·수정 화면에서 돌아왔을 때 목록만 새로 세운다.
  ///
  /// ⚠️ [load]를 다시 부르면 **입력 중이던 닉네임·소개가 서버 값으로 되돌아간다.**
  ///    저장하지 않은 편집을 날리지 않도록 배열만 갈아끼운다.
  ///    `ProfileItemSaver`가 저장 직후 `refreshMe()`를 부르므로 여기서는
  ///    다시 요청하지 않고 세션의 최신 프로필을 그대로 읽는다.
  void reloadItems() => _setItems(_auth.me.value?.profile);

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
          careers: careers.toList(),
          educations: educations.toList(),
          certifications: certifications.toList(),
          awards: awards.toList(),
          languages: languages.toList(),
          links: links.toList(),
        ),
      );
      await _auth.refreshMe();
      // 닫고 나서 토스트 — 순서를 뒤집으면 GetX가 라우트 대신 스낵바를 닫는다.
      _toast.backThen('프로필을 저장했어요.');
    } catch (e) {
      if (ApiError.from(e).code == 'VALIDATION_ERROR') {
        nicknameError.value = ApiError.from(e).displayMessage;
      }
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  // ── 항목 추가·수정 화면 이동 ────────────────────────────────
  // 인자가 없으면 추가, 있으면 수정이다. 돌아올 때 true를 받으면 목록만 갱신한다.

  Future<void> openCareer([int? index]) => _openItemScreen(
    AppRoutes.meProfileCareer,
    index == null ? null : CareerEditArgs(index, careers[index]),
  );

  Future<void> openLink([int? index]) => _openItemScreen(
    AppRoutes.meProfileLink,
    index == null ? null : LinkEditArgs(index, links[index]),
  );

  /// 이력은 4개 배열로 나뉘어 있어 종류와 위치를 함께 넘긴다.
  Future<void> openRecord([RecordKind? kind, int? index]) => _openItemScreen(
    AppRoutes.meProfileRecord,
    (kind == null || index == null)
        ? null
        : RecordEditArgs(kind, index, _recordAt(kind, index)),
  );

  Object _recordAt(RecordKind kind, int index) => switch (kind) {
    RecordKind.education => educations[index],
    RecordKind.certification => certifications[index],
    RecordKind.award => awards[index],
    RecordKind.language => languages[index],
  };

  Future<void> _openItemScreen(String route, Object? args) async {
    final saved = await Get.toNamed(route, arguments: args);
    if (saved == true) reloadItems();
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
