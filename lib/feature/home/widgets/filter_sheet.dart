import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import '../home_controller.dart';

/// 상태 칩 — 서버 status(open/closed)가 아니라 시각 기반 phase를 거른다.
/// 서버는 "진행 중"을 표현할 수 없어 이 필터는 클라이언트 몫이다.
const _statusOptions = [('open', '모집중'), ('live', '진행 중'), ('past', '지난 모임')];

String? statusLabel(String? value) =>
    _statusOptions.firstWhereOrNull((o) => o.$1 == value)?.$2;

/// 필터 시트 — 드래프트로 모았다가 "적용"에서 한 번에 반영한다.
/// (칩 하나 누를 때마다 재조회하면 네트워크가 요동친다.)
Future<void> showHomeFilterSheet(
  BuildContext context,
  HomeController controller,
) async {
  var category = controller.category.value;
  var interest = controller.interest.value;
  var status = controller.statusFilter.value;

  final applied = await IamBottomSheet.show<bool>(
    context,
    title: '필터',
    titleExtra: '원하는 조건을 골라보세요',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Group(
            label: '카테고리',
            children: [
              _chip(
                '전체',
                category == null,
                () => setSheetState(() => category = null),
              ),
              for (final c in controller.reference.categories)
                _chip(c.label, category == c.value.name, () {
                  setSheetState(
                    () => category = category == c.value.name
                        ? null
                        : c.value.name,
                  );
                }),
            ],
          ),
          _Group(
            label: '관심사',
            children: [
              _chip(
                '전체',
                interest == null,
                () => setSheetState(() => interest = null),
              ),
              for (final t in controller.reference.interests)
                _chip(t.label, interest == t.name.name, () {
                  setSheetState(
                    () =>
                        interest = interest == t.name.name ? null : t.name.name,
                  );
                }),
            ],
          ),
          _Group(
            label: '상태',
            children: [
              _chip(
                '전체',
                status == null,
                () => setSheetState(() => status = null),
              ),
              for (final o in _statusOptions)
                _chip(o.$2, status == o.$1, () {
                  setSheetState(() => status = status == o.$1 ? null : o.$1);
                }),
            ],
          ),
        ],
      ),
    ),
    footer: Row(
      children: [
        IamButton(
          label: '초기화',
          variant: IamButtonVariant.ghost,
          onPressed: () {
            category = null;
            interest = null;
            status = null;
            Navigator.of(context).pop(true);
          },
        ),
        const SizedBox(width: AppDimens.space2),
        Expanded(
          child: IamButton(
            label: '적용',
            block: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    ),
  );

  if (applied == true) {
    controller.applyFilter(
      category: category,
      interest: interest,
      status: status,
    );
  }
}

Widget _chip(String label, bool selected, VoidCallback onTap) => IamFilterChip(
  label: label,
  selected: selected,
  size: IamFilterChipSize.sm,
  onTap: onTap,
);

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              height: 1.3,
              fontWeight: AppTypography.semibold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space3),
          Wrap(
            spacing: AppDimens.space2,
            runSpacing: AppDimens.space2,
            children: children,
          ),
        ],
      ),
    );
  }
}
