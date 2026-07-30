import 'package:flutter_test/flutter_test.dart';

import 'package:iam/service/push_service.dart';

/// 포그라운드 배너의 알림 id.
///
/// `flutter_local_notifications` 는 id 가 32비트 정수를 넘으면 `show()` 를
/// 거부한다. `PushService` 는 푸시 실패를 전부 삼키도록 되어 있어서, 이 값이
/// 잘못되면 **아무 에러 없이 배너만 영영 안 뜬다**. 실제로 epoch ms 를 그대로
/// 시드로 쓴 적이 있고, 기기에 붙어 로그를 찍기 전까지 아무도 몰랐다.
/// 그 회귀를 막는 테스트다.
void main() {
  /// Android 가 받아주는 상한. 이걸 넘으면 플러그인이 던진다.
  const int32Max = 2147483647;

  test('epoch ms 를 넣어도 32비트 안에 들어간다', () {
    // 이 값이 실제로 터졌던 입력이다.
    expect(notificationId(1785389376031), lessThanOrEqualTo(int32Max));
  });

  test('미래의 epoch ms 도 안전하다', () {
    // 2286년. 시계가 아무리 커져도 상한을 넘으면 안 된다.
    expect(notificationId(9999999999999), lessThanOrEqualTo(int32Max));
  });

  test('음수가 나오지 않는다 — 플러그인은 범위 밖 음수도 거부한다', () {
    expect(notificationId(-1785389376031), greaterThanOrEqualTo(0));
  });

  test('시드 이후 증가를 반복해도 경계를 넘지 않는다', () {
    // 상한 근처에서 시작해도 +1 이 쌓여 32비트를 넘으면 안 된다.
    var id = notificationId(int32Max);
    for (var i = 0; i < 1000; i++) {
      id = notificationId(id + 1);
      expect(id, lessThanOrEqualTo(int32Max));
      expect(id, greaterThanOrEqualTo(0));
    }
  });

  test('작은 값은 그대로 통과한다', () {
    expect(notificationId(0), 0);
    expect(notificationId(42), 42);
  });
}
