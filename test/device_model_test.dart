import 'package:flutter_test/flutter_test.dart';

import 'package:iam/data/models/models.dart';

/// 서버 계약은 snake_case 다. 필드명이 어긋나면 등록이 400 으로 조용히
/// 실패하고, 그 결과는 "푸시가 안 온다"로만 나타나 원인 찾기가 괴롭다.
void main() {
  test('토큰 등록 요청은 snake_case 로 직렬화된다', () {
    expect(
      const DeviceRegisterRequest(token: 'abc123').toJson(),
      {'token': 'abc123', 'platform': 'android'},
    );
  });

  test('platform 기본값은 android 다', () {
    expect(const DeviceRegisterRequest(token: 'x').platform, 'android');
  });
}
