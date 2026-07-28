import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 경력·이력·링크 추가 화면이 공유하는 저장 로직.
///
/// ⚠️ **PATCH는 전체 교체다.** 한 항목만 추가하려 해도 나머지 배열을 전부
/// 실어 보내야 한다. 그래서 저장 전에 항상 현재 프로필을 먼저 읽는다
/// (웹의 `useProfileFormGate`가 막던 유실 사고).
class ProfileItemSaver {
  const ProfileItemSaver(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  /// [mutate]에 현재 프로필을 넘겨 새 요청을 만들게 한다.
  Future<bool> save(
    ProfileUpdateRequest Function(Profile current) mutate,
  ) async {
    try {
      final me = await _api.me();
      final current = me.profile;
      if (current == null) {
        _toast.error('프로필을 먼저 만들어 주세요.');
        return false;
      }
      await _api.updateProfile(mutate(current));
      await _auth.refreshMe();
      _toast.success('저장했어요.');
      return true;
    } catch (e) {
      _toast.showError(e);
      return false;
    }
  }

  /// 편집 대상 외 배열을 그대로 옮겨 담는다.
  static ProfileUpdateRequest carryOver(
    Profile p, {
    List<CareerItem>? careers,
    List<EducationItem>? educations,
    List<CertificationItem>? certifications,
    List<AwardItem>? awards,
    List<LanguageItem>? languages,
    List<LinkItem>? links,
  }) => ProfileUpdateRequest(
    careers: careers ?? p.careers ?? const [],
    educations: educations ?? p.educations ?? const [],
    certifications: certifications ?? p.certifications ?? const [],
    awards: awards ?? p.awards ?? const [],
    languages: languages ?? p.languages ?? const [],
    links: links ?? p.links ?? const [],
  );
}
