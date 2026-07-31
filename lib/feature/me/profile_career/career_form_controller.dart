import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';
import 'package:iam/service/services.dart';

/// v3-04 경력 추가·수정.
///
/// 라우트   : AppRoutes.meProfileCareer
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/career/CareerForm.tsx`
///
/// 수정 모드는 `Get.arguments`로 **배열 인덱스**를 받는다(웹의 `/career/[id]`와
/// 같은 식별 방식). 인자가 없으면 추가 모드다.
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

  /// 수정 중인 항목의 위치. null이면 추가 모드.
  int? editIndex;

  bool get isEdit => editIndex != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is! CareerEditArgs) return;
    editIndex = arg.index;
    _prefill(arg.item);
  }

  void _prefill(CareerItem item) {
    company.text = item.company;
    title.text = item.title ?? '';
    startYm.text = item.startYearMonth;
    endYm.text = item.endYearMonth ?? '';
    description.text = item.description ?? '';
    isCurrent.value = item.isCurrent;
    jobCategory.value = item.jobCategory;
  }

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
      await _saver.save(
        (p) => ProfileItemSaver.carryOver(
          p,
          careers: ProfileItemSaver.upsert(p.careers, item, editIndex),
        ),
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
        (p) => ProfileItemSaver.carryOver(
          p,
          careers: ProfileItemSaver.removeAt(p.careers, index),
        ),
        message: '경력을 삭제했어요.',
      );
      // 성공하면 saver가 화면을 닫고 토스트를 띄운다(순서 주의 — backThen 주석).
    } finally {
      isSaving.value = false;
    }
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
