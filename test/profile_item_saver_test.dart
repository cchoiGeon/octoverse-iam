import 'package:flutter_test/flutter_test.dart';

import 'package:iam/feature/me/profile_shared/profile_item_controller.dart';

/// 프로필 항목(경력·이력·링크)의 추가·교체·삭제 규칙 테스트.
///
/// 서버가 항목별 id를 주지 않아 **배열 인덱스로 식별**한다(웹
/// `/me/profile/career/[id]`의 id도 인덱스다). 그래서 저장 직전에 다시 읽은
/// 프로필과 화면이 들고 있던 인덱스가 어긋날 수 있고, 그때 무슨 일이 일어나야
/// 하는지가 이 함수들의 계약이다.
void main() {
  group('upsert — 추가·교체', () {
    test('인덱스가 null이면 끝에 추가한다', () {
      expect(ProfileItemSaver.upsert(['a', 'b'], 'c', null), ['a', 'b', 'c']);
    });

    test('원본이 null이어도 추가된다 (첫 항목)', () {
      expect(ProfileItemSaver.upsert<String>(null, 'a', null), ['a']);
    });

    test('인덱스를 주면 그 자리를 교체한다', () {
      expect(ProfileItemSaver.upsert(['a', 'b', 'c'], 'B', 1), ['a', 'B', 'c']);
    });

    test('원본을 건드리지 않는다 — 실패 시 되돌릴 수 있어야 한다', () {
      final original = ['a', 'b'];
      ProfileItemSaver.upsert(original, 'B', 1);
      expect(original, ['a', 'b']);
    });

    // 그 사이 다른 기기에서 항목이 지워지면 인덱스가 범위를 벗어난다.
    // 엉뚱한 항목을 덮어쓰는 것보다 하나 더 생기는 쪽이 되돌리기 쉽다.
    test('인덱스가 범위를 넘으면 덮어쓰지 않고 추가한다', () {
      expect(ProfileItemSaver.upsert(['a'], 'z', 5), ['a', 'z']);
    });

    test('음수 인덱스도 추가로 처리한다', () {
      expect(ProfileItemSaver.upsert(['a'], 'z', -1), ['a', 'z']);
    });
  });

  group('removeAt — 삭제', () {
    test('해당 위치를 지운다', () {
      expect(ProfileItemSaver.removeAt(['a', 'b', 'c'], 1), ['a', 'c']);
    });

    // 이미 지워진 항목을 또 지우려는 상황. 남은 것을 건드리면 안 된다.
    test('범위를 벗어나면 아무것도 지우지 않는다', () {
      expect(ProfileItemSaver.removeAt(['a', 'b'], 7), ['a', 'b']);
      expect(ProfileItemSaver.removeAt(['a', 'b'], -1), ['a', 'b']);
    });

    test('원본을 건드리지 않는다', () {
      final original = ['a', 'b'];
      ProfileItemSaver.removeAt(original, 0);
      expect(original, ['a', 'b']);
    });

    test('null이면 빈 목록을 돌려준다', () {
      expect(ProfileItemSaver.removeAt<String>(null, 0), isEmpty);
    });
  });
}
