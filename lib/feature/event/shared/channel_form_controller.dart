import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 모임 생성·수정이 공유하는 폼 상태.
///
/// 웹 대응: `IAM_web/src/components/app/ChannelForm.tsx`
/// (웹은 RHF+Zod, 여기서는 컨트롤러가 직접 검증한다 — 필드가 9개뿐이라
///  스키마 라이브러리를 들이는 것보다 읽기 쉽다.)
mixin ChannelFormMixin on GetxController {
  ApiClient get api;
  ReferenceService get reference;
  ToastService get toast;

  final title = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  final capacity = TextEditingController(text: '30');

  final Rxn<File> coverFile = Rxn<File>();
  final RxnString coverUrl = RxnString();
  final Rxn<EventCategory> category = Rxn<EventCategory>();
  final RxList<String> interestIds = <String>[].obs;
  final Rxn<DateTime> startAt = Rxn<DateTime>();
  final Rxn<DateTime> endAt = Rxn<DateTime>();
  final RxBool isPublic = true.obs;

  final RxnString titleError = RxnString();
  final RxnString locationError = RxnString();
  final RxnString categoryError = RxnString();
  final RxnString scheduleError = RxnString();
  final RxnString capacityError = RxnString();

  final RxBool isSubmitting = false.obs;

  void disposeFormControllers() {
    title.dispose();
    description.dispose();
    location.dispose();
    capacity.dispose();
  }

  Future<void> pickCover() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > kMaxImageBytes) {
        toast.error('이미지 크기는 5MB 이하여야 해요.');
        return;
      }
      coverFile.value = file;
    } catch (e) {
      toast.showError(e);
    }
  }

  void removeCover() {
    coverFile.value = null;
    coverUrl.value = null;
  }

  void setSchedule(DateTime start, DateTime end) {
    startAt.value = start;
    endAt.value = end;
    scheduleError.value = null;
  }

  bool validate() {
    titleError.value = title.text.trim().isEmpty ? '모임 이름을 입력해 주세요.' : null;
    locationError.value = location.text.trim().isEmpty ? '장소를 입력해 주세요.' : null;
    categoryError.value = category.value == null ? '카테고리를 선택해 주세요.' : null;

    final cap = int.tryParse(capacity.text.trim());
    capacityError.value = cap == null || cap < 1
        ? '정원을 1명 이상으로 입력해 주세요.'
        : null;

    if (startAt.value == null || endAt.value == null) {
      scheduleError.value = '시작·종료 일시를 정해주세요.';
    } else if (!endAt.value!.isAfter(startAt.value!)) {
      scheduleError.value = '종료가 시작보다 빠를 수 없어요.';
    } else {
      scheduleError.value = null;
    }

    return [
      titleError,
      locationError,
      categoryError,
      capacityError,
      scheduleError,
    ].every((e) => e.value == null);
  }

  /// 커버가 새로 선택됐으면 업로드해 URL을 얻는다.
  Future<String?> resolveCoverUrl() async {
    if (coverFile.value == null) return coverUrl.value;
    return (await api.uploadImage(coverFile.value!)).url;
  }

  ChannelCreateRequest buildRequest(String? cover) => ChannelCreateRequest(
    title: title.text.trim(),
    description: description.text.trim(),
    location: location.text.trim(),
    category: category.value!,
    // 폼의 시각은 KST 기준 — 서버로 보낼 때 UTC로 바꾼다.
    startAt: DateTimeUtils.toUtcIso(startAt.value!),
    endAt: DateTimeUtils.toUtcIso(endAt.value!),
    capacity: int.parse(capacity.text.trim()),
    isPublic: isPublic.value,
    coverImageUrl: cover,
    interestTagIds: interestIds.map(int.parse).toList(),
  );
}
