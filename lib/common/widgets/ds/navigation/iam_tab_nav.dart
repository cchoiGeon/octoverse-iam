import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// 탭 하나의 정의.
class IamTabItem {
  const IamTabItem({
    required this.key,
    required this.label,
    required this.icon,
    this.badge = false,
  });

  final String key;
  final String label;
  final IamIconName icon;

  /// true면 아이콘 우상단에 코랄 점.
  final bool badge;
}

/// 탭바 본체 높이(safe-area 제외) — 토큰 `--tabbar-h`.
/// 내부 콘텐츠는 8+24+3+17+6 = 58px 이라 이보다 커야 넘치지 않는다.
const double _tabHeight = AppDimens.tabbarHeight;

/// IamTabNav — IAM DS · navigation
///
/// 하단 탭 네비(홈·모임·찜·마이). 큰 터치 타깃 + safe-area 대응.
/// `IAM_web/src/components/ds/navigation/TabNav.tsx` 이식.
class IamTabNav extends StatelessWidget {
  const IamTabNav({
    super.key,
    required this.items,
    required this.active,
    this.onChanged,
  });

  final List<IamTabItem> items;

  /// 활성 탭의 key.
  final String active;
  final void Function(String key)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '주요 메뉴',
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.borderDefault)),
        ),
        // 홈 인디케이터 영역만큼 아래 여백을 준다.
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        // ⚠️ 높이를 반드시 고정한다. `CrossAxisAlignment.stretch` Row는 세로로
        //    최대한 늘어나려 하는데, bottomNavigationBar가 주는 최대 높이는
        //    화면 전체다 → 탭바가 화면을 다 먹고 본문이 사라진다.
        child: SizedBox(
          height: _tabHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final it in items)
                Expanded(
                  child: _Tab(item: it, on: it.key == active, onTap: onChanged),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.on, this.onTap});

  final IamTabItem item;
  final bool on;
  final void Function(String key)? onTap;

  @override
  Widget build(BuildContext context) {
    final color = on ? AppColors.primary : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: on,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(item.key),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IamIcon(
                    item.icon,
                    size: 24,
                    color: color,
                    // 활성 탭은 선을 살짝 굵게 — 색 대비만으로 부족한 경우 대비.
                    strokeWidth: on ? 2.4 : 2,
                  ),
                  if (item.badge)
                    Positioned(
                      top: -3,
                      right: -6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceCard,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: AppTypography.label.copyWith(
                  height: 1,
                  fontWeight: on
                      ? AppTypography.semibold
                      : AppTypography.medium,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
