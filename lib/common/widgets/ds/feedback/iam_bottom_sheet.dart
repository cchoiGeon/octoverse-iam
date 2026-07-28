import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamBottomSheet — IAM DS · feedback
///
/// 하단에서 올라오는 모달. 드래그 핸들 · 제목 · 본문(스크롤) · 하단 액션.
/// `IAM_web/src/components/ds/feedback/BottomSheet.tsx` 이식.
///
/// 웹은 `open` prop으로 제어했지만 Flutter는 [show]로 띄우고 결과를 await 한다.
class IamBottomSheet extends StatelessWidget {
  const IamBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.titleExtra,
    this.footer,
  });

  final Widget child;
  final String? title;

  /// 제목 우측 보조 문구.
  final String? titleExtra;

  /// 하단 고정 액션(적용 버튼 등).
  final Widget? footer;

  /// 시트를 띄우고 닫힐 때 값을 돌려받는다.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
    String? title,
    String? titleExtra,
    Widget? footer,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: const Color(0x00000000),
      barrierColor: AppColors.overlayScrim,
      // 내용이 길면 스크롤되어야 한다 — 기본 half-screen 제약을 푼다.
      isScrollControlled: true,
      builder: (ctx) => IamBottomSheet(
        title: title,
        titleExtra: titleExtra,
        footer: footer,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        // 시트가 화면을 다 덮지 않게 — 뒤 맥락이 조금 보여야 덜 답답하다.
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        maxWidth: AppDimens.maxContent,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radius2xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          if (title != null) _header(context),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space5,
                AppDimens.space2,
                AppDimens.space5,
                AppDimens.space5,
              ),
              child: child,
            ),
          ),
          if (footer != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppDimens.space5,
                AppDimens.space3,
                AppDimens.space5,
                AppDimens.space5 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space5,
        AppDimens.space3,
        AppDimens.space5,
        AppDimens.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title!, style: AppTypography.title2.copyWith(height: 1.35)),
          if (titleExtra != null) ...[
            const SizedBox(width: AppDimens.space2),
            Expanded(
              child: Text(
                titleExtra!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ] else
            const Spacer(),
          Semantics(
            button: true,
            label: '닫기',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: IamIcon(
                    IamIconName.close,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppDimens.space2),
    child: Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        ),
      ),
    ),
  );
}
