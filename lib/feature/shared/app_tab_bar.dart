import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/core/route/app_pages.dart';

/// 메인 탭 4개가 공유하는 하단 네비.
///
/// 라우트 매핑을 한 곳에 모아 화면마다 반복하지 않는다.
/// (홈·내 모임·찜·마이 — `AppRoutes.tabRoutes` 순서와 같다.)
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.active});

  /// 'home' | 'meetings' | 'likes' | 'me'
  final String active;

  static const _items = [
    IamTabItem(key: 'home', label: '홈', icon: IamIconName.home),
    IamTabItem(key: 'meetings', label: '모임', icon: IamIconName.calendar),
    IamTabItem(key: 'likes', label: '찜', icon: IamIconName.heart),
    IamTabItem(key: 'me', label: '마이', icon: IamIconName.user),
  ];

  static const _routes = {
    'home': AppRoutes.home,
    'meetings': AppRoutes.meMeetings,
    'likes': AppRoutes.meLikes,
    'me': AppRoutes.me,
  };

  @override
  Widget build(BuildContext context) {
    return IamTabNav(
      items: _items,
      active: active,
      onChanged: (key) {
        if (key == active) return;
        // 탭 전환은 스택을 쌓지 않는다 — 뒤로가기로 탭을 되짚지 않게.
        Get.offNamed(_routes[key]!);
      },
    );
  }
}
