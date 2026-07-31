import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import '../event_people_controller.dart';

/// 07b 관심사 필터 시트.
///
/// 웹 대응: `IAM_web/src/app/(app)/event/[slug]/people/page.tsx`의 `<FilterSheet>`
///
/// 홈 필터와 같은 드래프트→적용 패턴이다. 다른 점은 적용 버튼이 **결과 수를
/// 미리 보여준다**는 것 — 다 고르고 닫았는데 0명인 상황을 막는다.
///
/// 드래프트를 `ValueNotifier`로 두는 이유: `IamBottomSheet`의 footer는 `show()`
/// 시점에 한 번 만들어지는 위젯이라 본문의 `StatefulBuilder`로는 갱신되지 않는다.
/// 본문과 footer가 같은 notifier를 구독해야 버튼의 숫자가 따라 움직인다.
Future<void> showInterestFilterSheet(
  BuildContext context,
  EventPeopleController controller,
) async {
  final draft = ValueNotifier<List<String>>([...controller.appliedInterests]);
  final options = controller.interestOptions;

  try {
    final applied = await IamBottomSheet.show<List<String>>(
      context,
      title: '관심사 필터',
      titleExtra: '겹치는 관심사로 좁혀봐요',
      builder: (_) => ValueListenableBuilder<List<String>>(
        valueListenable: draft,
        builder: (_, value, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IamTagSelect(
              label: '관심사',
              options: options,
              value: value,
              onChanged: (next) => draft.value = next,
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(height: AppDimens.space3),
              _ResetButton(onTap: () => draft.value = const []),
            ],
          ],
        ),
      ),
      footer: ValueListenableBuilder<List<String>>(
        valueListenable: draft,
        builder: (ctx, value, __) => IamButton(
          label: '결과 보기 (${controller.draftMatchCount(value)}명)',
          size: IamButtonSize.lg,
          block: true,
          onPressed: () => Navigator.of(ctx).pop(value),
        ),
      ),
    );

    if (applied != null) controller.applyInterests(applied);
  } finally {
    draft.dispose();
  }
}

/// 텍스트만 있는 초기화 — 적용 버튼과 무게가 겹치지 않게 버튼으로 만들지 않는다.
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space1),
          child: Text(
            '초기화',
            style: AppTypography.bodyS.copyWith(
              height: 1,
              fontWeight: AppTypography.medium,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
