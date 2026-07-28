import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';

/// 참조 데이터(관심사·카테고리·스킬) 캐시.
/// `IAM_web/src/lib/services/reference.tsx` 이식.
///
/// **버전 전략** — 거의 안 바뀌는 데이터라 매번 받지 않는다:
///   1. 로컬 캐시에서 즉시 시드(첫 프레임에 칩이 비지 않게)
///   2. 백그라운드로 재조회
///   3. `version`이 다를 때만 캐시 교체
class ReferenceService extends GetxService {
  ReferenceService(this._api);

  final ApiClient _api;

  final RxList<InterestTag> interests = <InterestTag>[].obs;
  final RxList<CategoryOption> categories = <CategoryOption>[].obs;
  final RxList<SkillTag> skills = <SkillTag>[].obs;

  final RxBool isLoading = false.obs;

  String? _interestsVersion;
  String? _categoriesVersion;
  String? _skillsVersion;

  /// 앱 시작 시 1회. 캐시 시드 후 백그라운드 새로고침.
  Future<void> bootstrap() async {
    _seedFromCache();
    // await하지 않는다 — 참조 데이터가 늦어도 화면 진입은 막지 않는다.
    unawaited(refreshFromServer());
  }

  void _seedFromCache() {
    final raw = Storage.read<String>(kStorageReference);
    if (raw == null) return;
    try {
      final c = jsonDecode(raw) as Map<String, dynamic>;
      _interestsVersion = c['interests_version'] as String?;
      _categoriesVersion = c['categories_version'] as String?;
      _skillsVersion = c['skills_version'] as String?;
      interests.value = (c['interests'] as List? ?? [])
          .map((e) => InterestTag.fromJson(e as Map<String, dynamic>))
          .toList();
      categories.value = (c['categories'] as List? ?? [])
          .map((e) => CategoryOption.fromJson(e as Map<String, dynamic>))
          .toList();
      skills.value = (c['skills'] as List? ?? [])
          .map((e) => SkillTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 캐시가 깨졌으면 무시하고 서버에서 다시 받는다.
    }
  }

  Future<void> refreshFromServer() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.interestTags(),
        _api.eventCategories(),
        _api.skillTags(),
      ]);
      final i = results[0] as InterestTagsResponse;
      final c = results[1] as EventCategoriesResponse;
      final s = results[2] as SkillTagsResponse;

      final changed =
          i.version != _interestsVersion ||
          c.version != _categoriesVersion ||
          s.version != _skillsVersion;

      interests.value = i.interests;
      categories.value = c.categories;
      skills.value = s.skills;

      if (changed) {
        _interestsVersion = i.version;
        _categoriesVersion = c.version;
        _skillsVersion = s.version;
        await _writeCache();
      }
    } catch (_) {
      // 실패해도 캐시본으로 계속 동작한다.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _writeCache() => Storage.write(
    kStorageReference,
    jsonEncode({
      'interests_version': _interestsVersion,
      'categories_version': _categoriesVersion,
      'skills_version': _skillsVersion,
      'interests': interests.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'skills': skills.map((e) => e.toJson()).toList(),
    }),
  );

  // ── 조회 헬퍼 ─────────────────────────────────────────────

  /// 관심사 태그 id → 한국어 라벨. 못 찾으면 id를 그대로 보여준다.
  String interestLabelById(int id) =>
      interests.firstWhereOrNull((t) => t.id == id)?.label ?? '$id';

  /// 카테고리 값 → 라벨. 서버 라벨이 없으면 enum 라벨로 폴백.
  String categoryLabel(EventCategory value) =>
      categories.firstWhereOrNull((c) => c.value == value)?.label ??
      value.label;
}
