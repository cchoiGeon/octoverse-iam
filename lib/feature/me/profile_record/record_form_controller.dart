import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';
import 'package:iam/service/services.dart';

/// v3-05 이력 추가 — 학력·자격증·수상·어학.
///
/// 라우트   : AppRoutes.meProfileRecord
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/record/RecordForm.tsx`
///
/// 서버는 4개 배열로 나뉘어 있지만 사용자에겐 "이력" 하나로 보인다 —
/// 종류를 고르면 그에 맞는 필드만 나온다.
///
/// 수정 모드는 `Get.arguments`([RecordEditArgs])로 들어온다. 없으면 추가 모드.
/// ⚠️ 수정 중에는 **종류를 바꿀 수 없다** — 종류가 곧 어느 배열이냐이므로,
///    바꾸면 원래 배열에서 지우고 다른 배열에 넣는 이동이 된다. 그건 삭제 후
///    새로 추가하는 것과 같아서 굳이 한 화면에 욱여넣지 않는다.
class MeProfileRecordController extends GetxController {
  MeProfileRecordController(ApiClient api, AuthService auth, ToastService toast)
    : _saver = ProfileItemSaver(api, auth, toast);

  final ProfileItemSaver _saver;

  final Rx<RecordKind> kind = RecordKind.education.obs;

  /// 수정 중인 항목의 위치. null이면 추가 모드.
  int? editIndex;

  bool get isEdit => editIndex != null;

  final school = TextEditingController();
  final major = TextEditingController();
  final degree = TextEditingController();
  final eduStart = TextEditingController();
  final eduEnd = TextEditingController();
  final certName = TextEditingController();
  final certIssuer = TextEditingController();
  final certDate = TextEditingController();
  final awardName = TextEditingController();
  final awardOrg = TextEditingController();
  final awardDate = TextEditingController();
  final language = TextEditingController();
  final langScore = TextEditingController();

  final Rxn<LanguageLevel> langLevel = Rxn<LanguageLevel>();
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    for (final c in [
      school,
      major,
      degree,
      eduStart,
      eduEnd,
      certName,
      certIssuer,
      certDate,
      awardName,
      awardOrg,
      awardDate,
      language,
      langScore,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is! RecordEditArgs) return;
    editIndex = arg.index;
    kind.value = arg.kind;
    _prefill(arg.kind, arg.item);
  }

  void _prefill(RecordKind k, Object item) {
    switch (k) {
      case RecordKind.education:
        final e = item as EducationItem;
        school.text = e.school ?? '';
        major.text = e.major ?? '';
        degree.text = e.degree ?? '';
        eduStart.text = e.startYearMonth ?? '';
        eduEnd.text = e.endYearMonth ?? '';
      case RecordKind.certification:
        final c = item as CertificationItem;
        certName.text = c.name;
        certIssuer.text = c.issuer ?? '';
        certDate.text = c.acquiredDate ?? '';
      case RecordKind.award:
        final a = item as AwardItem;
        awardName.text = a.name;
        awardOrg.text = a.organization ?? '';
        awardDate.text = a.awardedDate ?? '';
      case RecordKind.language:
        final l = item as LanguageItem;
        language.text = l.language;
        langScore.text = l.score ?? '';
        langLevel.value = l.level;
    }
  }

  /// 종류를 바꾸면 입력값을 비운다 — 남아 있으면 엉뚱한 배열에 섞인다.
  /// 수정 모드에서는 호출되지 않는다(화면이 선택기를 잠근다).
  void setKind(RecordKind next) {
    if (isEdit) return;
    kind.value = next;
    error.value = null;
    for (final c in [
      school,
      major,
      degree,
      eduStart,
      eduEnd,
      certName,
      certIssuer,
      certDate,
      awardName,
      awardOrg,
      awardDate,
      language,
      langScore,
    ]) {
      c.clear();
    }
    langLevel.value = null;
  }

  bool _validate() {
    final ok = switch (kind.value) {
      RecordKind.education =>
        school.text.trim().isNotEmpty || major.text.trim().isNotEmpty,
      RecordKind.certification => certName.text.trim().isNotEmpty,
      RecordKind.award => awardName.text.trim().isNotEmpty,
      RecordKind.language => language.text.trim().isNotEmpty,
    };
    error.value = ok ? null : '필수 항목을 입력해 주세요.';
    return ok;
  }

  Future<void> save() async {
    if (isSaving.value || !_validate()) return;
    isSaving.value = true;
    try {
      await _saver.save(
        (p) => switch (kind.value) {
          RecordKind.education => ProfileItemSaver.carryOver(
            p,
            educations: ProfileItemSaver.upsert(
              p.educations,
              EducationItem(
                school: _orNull(school.text),
                major: _orNull(major.text),
                degree: _orNull(degree.text),
                startYearMonth: _orNull(eduStart.text),
                endYearMonth: _orNull(eduEnd.text),
              ),
              editIndex,
            ),
          ),
          RecordKind.certification => ProfileItemSaver.carryOver(
            p,
            certifications: ProfileItemSaver.upsert(
              p.certifications,
              CertificationItem(
                name: certName.text.trim(),
                issuer: _orNull(certIssuer.text),
                acquiredDate: _orNull(certDate.text),
              ),
              editIndex,
            ),
          ),
          RecordKind.award => ProfileItemSaver.carryOver(
            p,
            awards: ProfileItemSaver.upsert(
              p.awards,
              AwardItem(
                name: awardName.text.trim(),
                organization: _orNull(awardOrg.text),
                awardedDate: _orNull(awardDate.text),
              ),
              editIndex,
            ),
          ),
          RecordKind.language => ProfileItemSaver.carryOver(
            p,
            languages: ProfileItemSaver.upsert(
              p.languages,
              LanguageItem(
                language: language.text.trim(),
                level: langLevel.value,
                score: _orNull(langScore.text),
              ),
              editIndex,
            ),
          ),
        },
      );
      // 성공하면 saver가 화면을 닫고 토스트를 띄운다(순서 주의 — backThen 주석).
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
        (p) => switch (kind.value) {
          RecordKind.education => ProfileItemSaver.carryOver(
            p,
            educations: ProfileItemSaver.removeAt(p.educations, index),
          ),
          RecordKind.certification => ProfileItemSaver.carryOver(
            p,
            certifications: ProfileItemSaver.removeAt(p.certifications, index),
          ),
          RecordKind.award => ProfileItemSaver.carryOver(
            p,
            awards: ProfileItemSaver.removeAt(p.awards, index),
          ),
          RecordKind.language => ProfileItemSaver.carryOver(
            p,
            languages: ProfileItemSaver.removeAt(p.languages, index),
          ),
        },
        message: '${kind.value.label}을 삭제했어요.',
      );
      // 성공하면 saver가 화면을 닫고 토스트를 띄운다(순서 주의 — backThen 주석).
    } finally {
      isSaving.value = false;
    }
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
