import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';
import 'package:iam/service/services.dart';

/// v3-04 경력 추가.
///
/// 라우트   : AppRoutes.meProfileCareer
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/career/CareerForm.tsx`
class MeProfileCareerController extends GetxController {
  MeProfileCareerController(ApiClient api, AuthService auth, ToastService toast)
    : _saver = ProfileItemSaver(api, auth, toast);

  final ProfileItemSaver _saver;

  final company = TextEditingController();
  final title = TextEditingController();
  final startYm = TextEditingController();
  final endYm = TextEditingController();
  final description = TextEditingController();

  final RxBool isCurrent = false.obs;
  final Rxn<JobCategory> jobCategory = Rxn<JobCategory>();
  final RxBool isSaving = false.obs;
  final RxnString companyError = RxnString();
  final RxnString startError = RxnString();

  @override
  void onClose() {
    for (final c in [company, title, startYm, endYm, description]) {
      c.dispose();
    }
    super.onClose();
  }

  bool _validate() {
    companyError.value = company.text.trim().isEmpty ? '회사명을 입력해 주세요.' : null;
    startError.value = startYm.text.trim().isEmpty ? '시작 시점을 입력해 주세요.' : null;
    return companyError.value == null && startError.value == null;
  }

  Future<void> save() async {
    if (isSaving.value || !_validate()) return;
    isSaving.value = true;
    try {
      final item = CareerItem(
        company: company.text.trim(),
        title: _orNull(title.text),
        startYearMonth: startYm.text.trim(),
        endYearMonth: isCurrent.value ? null : _orNull(endYm.text),
        isCurrent: isCurrent.value,
        description: _orNull(description.text),
        jobCategory: jobCategory.value,
      );
      final ok = await _saver.save(
        (p) => ProfileItemSaver.carryOver(p, careers: [...?p.careers, item]),
      );
      if (ok) Get.back(result: true);
    } finally {
      isSaving.value = false;
    }
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
