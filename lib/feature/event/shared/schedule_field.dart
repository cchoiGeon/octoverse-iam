import 'package:flutter/material.dart' show showDatePicker;
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';

/// 시작·종료 일시 입력.
///
/// **종료는 필수다** — 모임 상태(모집중/진행 중/지난 모임)를 판정하는 기준이라
/// 비워둘 수 없다. 기본값은 시작 +2시간이고 "얼마 동안" 프리셋으로 조정한다.
///
/// 웹 대응: `IAM_web/src/components/app/ScheduleField.tsx`
/// 디자인 : Figma `3.UI` node 347:2 (07 일정 설정 바텀시트)
class ScheduleField extends StatelessWidget {
  const ScheduleField({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
    this.error,
  });

  final DateTime? start;
  final DateTime? end;

  /// (시작, 종료) — 둘 다 확정된 값으로 넘어온다.
  final void Function(DateTime start, DateTime end) onChanged;

  final String? error;

  static const _durations = [1, 2, 3];
  static const _defaultDurationHours = 2;

  @override
  Widget build(BuildContext context) {
    final hasValue = start != null && end != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          const TextSpan(
            text: '일정',
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error600),
              ),
            ],
          ),
          style: AppTypography.bodyS.copyWith(
            height: 1.3,
            fontWeight: AppTypography.semibold,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        _row(
          context,
          label: '시작',
          value: hasValue
              ? '${DateTimeUtils.eventDate(start!.toUtc().toIso8601String())} '
                    '${DateTimeUtils.time(start!.toUtc().toIso8601String())}'
              : '날짜와 시간을 골라주세요',
          empty: !hasValue,
          onTap: () => _pickStart(context),
        ),
        if (hasValue) ...[
          const SizedBox(height: AppDimens.space2),
          _row(
            context,
            label: '종료',
            value:
                '${DateTimeUtils.eventDate(end!.toUtc().toIso8601String())} '
                '${DateTimeUtils.time(end!.toUtc().toIso8601String())}',
            empty: false,
            onTap: () => _pickDuration(context),
          ),
          const SizedBox(height: AppDimens.space3),
          _durationRow(),
        ],
        if (error != null) ...[
          const SizedBox(height: AppDimens.space2),
          Text(
            error!,
            style: AppTypography.caption.copyWith(
              height: 1.4,
              color: AppColors.error700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String value,
    required bool empty,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label $value',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(
              color: AppColors.borderStrong,
              width: AppDimens.borderWidthStrong,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            children: [
              const IamIcon(
                IamIconName.calendar,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimens.space2),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  height: 1,
                  fontWeight: AppTypography.semibold,
                ),
              ),
              // Spacer 를 같이 두면 남은 폭을 둘이 반씩 나눠 가져서 값이
              // "날짜와 시간을 골라주…" 처럼 잘린다. Expanded 하나로 남은 폭을
              // 전부 값에 주고, 오른쪽 정렬로 라벨과 떨어뜨린다.
              const SizedBox(width: AppDimens.space2),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.body.copyWith(
                    height: 1,
                    color: empty
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "얼마 동안" — 종료 시각을 직접 고르는 대신 길이로 정한다.
  /// 대부분의 모임은 1~3시간이라 이 편이 빠르다.
  Widget _durationRow() {
    final hours = end!.difference(start!).inMinutes / 60.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '얼마 동안',
          style: AppTypography.bodyS.copyWith(
            height: 1.4,
            fontWeight: AppTypography.medium,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final h in _durations)
              IamFilterChip(
                label: '$h시간',
                selected: hours == h,
                size: IamFilterChipSize.sm,
                onTap: () => onChanged(start!, start!.add(Duration(hours: h))),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickStart(BuildContext context) async {
    final now = DateTime.now();
    final base = start ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      // 지난 날짜로 모임을 만들 이유가 없다.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ko', 'KR'),
    );
    if (date == null || !context.mounted) return;

    final hour = await _pickHour(context, base.hour);
    if (hour == null) return;

    final nextStart = DateTime(date.year, date.month, date.day, hour);
    final duration = start != null && end != null
        ? end!.difference(start!)
        : const Duration(hours: _defaultDurationHours);
    onChanged(nextStart, nextStart.add(duration));
  }

  Future<int?> _pickHour(BuildContext context, int initial) {
    return IamBottomSheet.show<int>(
      context,
      title: '시작 시간',
      titleExtra: '1시간 단위',
      builder: (ctx) => Wrap(
        spacing: AppDimens.space2,
        runSpacing: AppDimens.space2,
        children: [
          for (var h = 0; h < 24; h++)
            IamFilterChip(
              label: _hourLabel(h),
              selected: h == initial,
              size: IamFilterChipSize.sm,
              indicator: false,
              onTap: () => Navigator.of(ctx).pop(h),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDuration(BuildContext context) async {
    final picked = await IamBottomSheet.show<int>(
      context,
      title: '얼마 동안',
      builder: (ctx) => Wrap(
        spacing: AppDimens.space2,
        runSpacing: AppDimens.space2,
        children: [
          for (final h in [1, 2, 3, 4, 6, 8])
            IamFilterChip(
              label: '$h시간',
              size: IamFilterChipSize.sm,
              indicator: false,
              onTap: () => Navigator.of(ctx).pop(h),
            ),
        ],
      ),
    );
    if (picked != null) {
      onChanged(start!, start!.add(Duration(hours: picked)));
    }
  }

  String _hourLabel(int h) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${h < 12 ? '오전' : '오후'} $h12시';
  }
}
