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
class MeProfileRecordController extends GetxController {
  MeProfileRecordController(ApiClient api, AuthService auth, ToastService toast)
    : _saver = ProfileItemSaver(api, auth, toast);

  final ProfileItemSaver _saver;

  final Rx<RecordKind> kind = RecordKind.education.obs;

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

  /// 종류를 바꾸면 입력값을 비운다 — 남아 있으면 엉뚱한 배열에 섞인다.
  void setKind(RecordKind next) {
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
      final ok = await _saver.save(
        (p) => switch (kind.value) {
          RecordKind.education => ProfileItemSaver.carryOver(
            p,
            educations: [
              ...?p.educations,
              EducationItem(
                school: _orNull(school.text),
                major: _orNull(major.text),
                degree: _orNull(degree.text),
                startYearMonth: _orNull(eduStart.text),
                endYearMonth: _orNull(eduEnd.text),
              ),
            ],
          ),
          RecordKind.certification => ProfileItemSaver.carryOver(
            p,
            certifications: [
              ...?p.certifications,
              CertificationItem(
                name: certName.text.trim(),
                issuer: _orNull(certIssuer.text),
                acquiredDate: _orNull(certDate.text),
              ),
            ],
          ),
          RecordKind.award => ProfileItemSaver.carryOver(
            p,
            awards: [
              ...?p.awards,
              AwardItem(
                name: awardName.text.trim(),
                organization: _orNull(awardOrg.text),
                awardedDate: _orNull(awardDate.text),
              ),
            ],
          ),
          RecordKind.language => ProfileItemSaver.carryOver(
            p,
            languages: [
              ...?p.languages,
              LanguageItem(
                language: language.text.trim(),
                level: langLevel.value,
                score: _orNull(langScore.text),
              ),
            ],
          ),
        },
      );
      if (ok) Get.back(result: true);
    } finally {
      isSaving.value = false;
    }
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
