import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 경력·이력·링크 추가·수정 화면이 공유하는 저장 로직.
///
/// ⚠️ **PATCH는 전체 교체다.** 한 항목만 건드리려 해도 나머지 배열을 전부
/// 실어 보내야 한다. 그래서 저장 전에 항상 현재 프로필을 먼저 읽는다
/// (웹의 `useProfileFormGate`가 막던 유실 사고).
///
/// **항목 식별은 배열 인덱스다** — 웹(`/me/profile/career/[id]`의 id = 인덱스)과
/// 같은 방식이다. 서버가 항목별 id를 주지 않아 다른 수단이 없다.
/// 저장 직전에 프로필을 다시 읽으므로, 그 사이 다른 기기에서 항목이 추가·삭제되면
/// 인덱스가 밀릴 수 있다. [upsert]·[removeAt]이 범위를 벗어난 인덱스를 흘려보내지
/// 않도록 막아 두었지만, 이 창 자체는 웹과 동일하게 남아 있다.
class ProfileItemSaver {
  const ProfileItemSaver(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  /// [mutate]에 현재 프로필을 넘겨 새 요청을 만들게 한다.
  ///
  /// 성공하면 **화면을 닫고 나서** 토스트를 띄운다([ToastService.backThen]).
  /// 순서를 뒤집으면 GetX가 라우트 대신 스낵바를 닫아 화면이 그대로 남는다 —
  /// 자세한 이유는 `backThen` 주석에 있다.
  Future<bool> save(
    ProfileUpdateRequest Function(Profile current) mutate, {
    String message = '저장했어요.',
  }) async {
    try {
      final me = await _api.me();
      final current = me.profile;
      if (current == null) {
        _toast.error('프로필을 먼저 만들어 주세요.');
        return false;
      }
      await _api.updateProfile(mutate(current));
      await _auth.refreshMe();
      // 목록 화면이 `true`를 받아야 항목을 새로 세운다.
      _toast.backThen(message, result: true);
      return true;
    } catch (e) {
      _toast.showError(e);
      return false;
    }
  }

  /// [index]가 null이면 끝에 추가, 아니면 그 자리를 [item]으로 교체한다.
  ///
  /// 인덱스가 범위를 벗어나면(= 그 사이 목록이 바뀌었다) **교체 대신 추가**한다.
  /// 엉뚱한 항목을 덮어쓰는 것보다 하나 더 생기는 쪽이 되돌리기 쉽다.
  static List<T> upsert<T>(List<T>? existing, T item, int? index) {
    final list = [...?existing];
    if (index == null || index < 0 || index >= list.length) {
      return [...list, item];
    }
    list[index] = item;
    return list;
  }

  /// [index] 자리를 지운다. 범위를 벗어나면 원본을 그대로 돌려준다.
  static List<T> removeAt<T>(List<T>? existing, int index) {
    final list = [...?existing];
    if (index < 0 || index >= list.length) return list;
    return list..removeAt(index);
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

/// 수정 화면 진입 인자.
///
/// 인덱스만 넘기고 폼이 프로필을 다시 읽게 할 수도 있지만, 목록 화면이 이미
/// 항목을 들고 있으므로 그대로 넘긴다 — 폼이 뜨기 전 왕복이 한 번 줄어든다.
/// (저장 시점에는 [ProfileItemSaver.save]가 어차피 최신 프로필을 다시 읽는다.)
class CareerEditArgs {
  const CareerEditArgs(this.index, this.item);

  final int index;
  final CareerItem item;
}

class LinkEditArgs {
  const LinkEditArgs(this.index, this.item);

  final int index;
  final LinkItem item;
}

/// 이력 수정 인자 — 서버가 이력을 4개 배열로 나눠 두어
/// "몇 번째"만으로는 어느 배열인지 알 수 없다.
///
/// 웹의 `/me/profile/record/{kind}-{index}` 경로와 같은 정보를 담는다.
/// [item]의 실제 타입은 [kind]가 정한다(education → EducationItem …).
class RecordEditArgs {
  const RecordEditArgs(this.kind, this.index, this.item);

  final RecordKind kind;
  final int index;
  final Object item;
}
