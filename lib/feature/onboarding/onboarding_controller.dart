import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 02·03 프로필 작성 — 3스텝.
///
/// 라우트   : AppRoutes.onboarding
/// 웹 대응  : `IAM_web/src/app/(auth)/onboarding/page.tsx`
/// 디자인   : Figma `3.UI` v3 보드 (239:702 · 239:752)
///
/// **제출은 3단계다** — 서버 계약이 그렇게 생겼다:
///   1. `POST /users/me/profile`  — 프로필 본체(경력·이력·링크 임베드)
///   2. `PATCH /users/me/profile` — 관심사. CreateProfileDto에 `interest_tag_ids`가 없다
///   3. `POST /auth/signup`       — 약관 동의
class OnboardingController extends GetxController {
  OnboardingController(
    this._api,
    this._auth,
    this._reference,
    this._toast,
    this._push,
  );

  final ApiClient _api;
  final AuthService _auth;
  final ReferenceService _reference;
  final ToastService _toast;
  final PushService _push;

  static const steps = ['프로필', '경력·이력', '약관 동의'];

  final RxInt step = 0.obs;
  final RxBool isSubmitting = false.obs;

  // ── Step 1 · 기본 정보 ──────────────────────────────────────
  final nickname = TextEditingController();
  final oneLiner = TextEditingController();
  final introduction = TextEditingController();

  final Rxn<File> photo = Rxn<File>();
  final RxList<String> interestIds = <String>[].obs;
  final RxList<String> skills = <String>[].obs;

  final RxnString nicknameError = RxnString();

  // ── Step 2 · 경력·이력·링크 ─────────────────────────────────
  final RxList<CareerItem> careers = <CareerItem>[].obs;
  final RxList<EducationItem> educations = <EducationItem>[].obs;
  final RxList<CertificationItem> certifications = <CertificationItem>[].obs;
  final RxList<AwardItem> awards = <AwardItem>[].obs;
  final RxList<LanguageItem> languages = <LanguageItem>[].obs;
  final RxList<LinkItem> links = <LinkItem>[].obs;

  // ── Step 3 · 약관 ───────────────────────────────────────────
  final RxBool agreedTerms = false.obs;
  final RxBool agreedPrivacy = false.obs;
  final RxBool emailOptIn = true.obs;

  bool get canSubmit => agreedTerms.value && agreedPrivacy.value;

  /// 참조 데이터 — 관심사·스킬 선택지.
  List<InterestTag> get interestOptions => _reference.interests;
  List<SkillTag> get skillOptions => _reference.skills;

  @override
  void onClose() {
    nickname.dispose();
    oneLiner.dispose();
    introduction.dispose();
    super.onClose();
  }

  // ── 사진 ────────────────────────────────────────────────────
  Future<void> pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // 5MB 제한이 있으니 미리 줄여 보낸다 — 서버 거절(IMAGE_TOO_LARGE)을 예방.
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > kMaxImageBytes) {
        _toast.error('이미지 크기는 5MB 이하여야 해요.');
        return;
      }
      photo.value = file;
    } catch (e) {
      _toast.showError(e);
    }
  }

  void removePhoto() => photo.value = null;

  // ── 단계 이동 ───────────────────────────────────────────────
  void next() {
    if (step.value == 0 && !_validateStep1()) return;
    if (step.value < steps.length - 1) step.value++;
  }

  void back() {
    if (step.value > 0) step.value--;
  }

  /// "다음에 하기" — Step 2에서 입력한 것을 버리고 약관으로 넘어간다.
  void skipHistory() {
    careers.clear();
    educations.clear();
    certifications.clear();
    awards.clear();
    languages.clear();
    links.clear();
    step.value = 2;
  }

  bool _validateStep1() {
    nicknameError.value = nickname.text.trim().isEmpty ? '닉네임을 입력해 주세요.' : null;
    return nicknameError.value == null;
  }

  // ── Step 2 항목 추가·삭제 ───────────────────────────────────
  void addCareer(CareerItem item) => careers.add(item);
  void removeCareer(int i) => careers.removeAt(i);

  void addEducation(EducationItem item) => educations.add(item);
  void addCertification(CertificationItem item) => certifications.add(item);
  void addAward(AwardItem item) => awards.add(item);
  void addLanguage(LanguageItem item) => languages.add(item);

  /// 이력 4종을 한 목록으로 합쳐 보여주기 위한 뷰 모델.
  List<RecordEntry> get recordEntries => [
    for (var i = 0; i < educations.length; i++)
      RecordEntry(
        kind: RecordKind.education,
        index: i,
        title: educations[i].school ?? educations[i].major ?? '학력',
        subtitle: [
          RecordKind.education.label,
          if (educations[i].major != null) educations[i].major!,
        ].join(' · '),
      ),
    for (var i = 0; i < certifications.length; i++)
      RecordEntry(
        kind: RecordKind.certification,
        index: i,
        title: certifications[i].name,
        subtitle: [
          RecordKind.certification.label,
          if (certifications[i].issuer != null) certifications[i].issuer!,
        ].join(' · '),
      ),
    for (var i = 0; i < awards.length; i++)
      RecordEntry(
        kind: RecordKind.award,
        index: i,
        title: awards[i].name,
        subtitle: [
          RecordKind.award.label,
          if (awards[i].organization != null) awards[i].organization!,
        ].join(' · '),
      ),
    for (var i = 0; i < languages.length; i++)
      RecordEntry(
        kind: RecordKind.language,
        index: i,
        title: languages[i].language,
        subtitle: [
          RecordKind.language.label,
          if (languages[i].level != null) languages[i].level!.label,
          if (languages[i].score != null) languages[i].score!,
        ].join(' · '),
      ),
  ];

  void removeRecord(RecordEntry e) {
    switch (e.kind) {
      case RecordKind.education:
        educations.removeAt(e.index);
      case RecordKind.certification:
        certifications.removeAt(e.index);
      case RecordKind.award:
        awards.removeAt(e.index);
      case RecordKind.language:
        languages.removeAt(e.index);
    }
  }

  /// 링크는 최대 5개.
  bool addLink(LinkItem item) {
    if (links.length >= kMaxLinks) {
      _toast.error('외부 링크는 최대 $kMaxLinks개까지 추가할 수 있어요.');
      return false;
    }
    links.add(item);
    return true;
  }

  void removeLink(int i) => links.removeAt(i);

  // ── 제출 ────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!canSubmit || isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final photoUrl = await _uploadPhotoIfAny();

      // (1) 프로필 본체 — 배열은 통째로 설정된다.
      await _api.createProfile(
        ProfileCreateRequest(
          nickname: nickname.text.trim(),
          oneLiner: _orNull(oneLiner.text),
          introduction: _orNull(introduction.text),
          photoUrl: photoUrl,
          skills: skills.isEmpty ? null : skills.toList(),
          careers: careers.isEmpty ? null : careers.toList(),
          educations: educations.isEmpty ? null : educations.toList(),
          certifications: certifications.isEmpty
              ? null
              : certifications.toList(),
          awards: awards.isEmpty ? null : awards.toList(),
          languages: languages.isEmpty ? null : languages.toList(),
          links: links.isEmpty ? null : links.toList(),
        ),
      );

      // (2) 관심사 — CreateProfileDto엔 없어서 PATCH로 따로 보낸다.
      if (interestIds.isNotEmpty) {
        await _api.updateProfile(
          ProfileUpdateRequest(
            interestTagIds: interestIds.map(int.parse).toList(),
          ),
        );
      }

      // (3) 약관 동의. 이미 가입된 계정이면 설정 갱신으로 우회한다.
      try {
        await _auth.signup(
          SignupRequest(
            termsAgreed: agreedTerms.value,
            privacyAgreed: agreedPrivacy.value,
            emailNotificationEnabled: emailOptIn.value,
          ),
        );
      } catch (e) {
        if (ApiError.from(e).code != 'ALREADY_SIGNED_UP') rethrow;
        await _api.updateSettings(
          SettingsUpdateRequest(emailNotificationEnabled: emailOptIn.value),
        );
      }

      await _auth.refreshMe();
      _toast.success('가입이 완료됐어요. 환영합니다!');
      // 여기가 알림 권한을 물어보기 가장 좋은 시점이다 — 방금 프로필을 만든
      // 사람에게 "모임 리마인더를 받겠냐"는 맥락이 서 있다.
      // 거부해도 그냥 넘어간다(내부에서 삼킨다).
      await _push.requestPermissionAndRegister();
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> _uploadPhotoIfAny() async {
    final file = photo.value;
    if (file == null) return null;
    final res = await _api.uploadImage(file);
    return res.url;
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}

/// 이력 4종을 한 리스트로 보여주기 위한 표시용 항목.
class RecordEntry {
  const RecordEntry({
    required this.kind,
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final RecordKind kind;

  /// 해당 종류 배열 안에서의 위치(삭제용).
  final int index;

  final String title;
  final String subtitle;
}
