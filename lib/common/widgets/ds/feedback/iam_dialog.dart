import 'package:flutter/material.dart' show showDialog;
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

enum IamDialogTone { normal, danger }

/// IamDialog — IAM DS · feedback
///
/// 중앙 확인 모달. `IAM_web/src/components/ds/feedback/Dialog.tsx` 이식.
///
/// 웹은 `open` prop으로 렌더를 제어했지만 Flutter는 [show]로 띄우고
/// 결과(bool)를 await 한다 — 호출부가 훨씬 단순해진다.
class IamDialog extends StatelessWidget {
  const IamDialog({
    super.key,
    this.title,
    this.description,
    this.body,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.showCancel = true,
    this.tone = IamDialogTone.normal,
  });

  final String? title;
  final String? description;
  final Widget? body;
  final String confirmText;
  final String cancelText;
  final bool showCancel;
  final IamDialogTone tone;

  /// 확인이면 true, 취소·스크림 탭이면 false.
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? description,
    Widget? body,
    String confirmText = '확인',
    String cancelText = '취소',
    bool showCancel = true,
    IamDialogTone tone = IamDialogTone.normal,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      // 취소 가능한 모달만 스크림 탭으로 닫는다.
      barrierDismissible: showCancel,
      barrierColor: AppColors.overlayScrim,
      builder: (_) => IamDialog(
        title: title,
        description: description,
        body: body,
        confirmText: confirmText,
        cancelText: cancelText,
        showCancel: showCancel,
        tone: tone,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space5,
                AppDimens.space6,
                AppDimens.space5,
                AppDimens.space4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppDimens.radius2xl),
                boxShadow: AppShadows.elev4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: AppTypography.title2.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: AppDimens.space2),
                  ],
                  if (description != null) ...[
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space5),
                  ],
                  if (body != null) ...[
                    body!,
                    const SizedBox(height: AppDimens.space2),
                  ],
                  Row(
                    children: [
                      if (showCancel) ...[
                        Expanded(
                          child: _Action(
                            label: cancelText,
                            background: AppColors.surfaceSunken,
                            foreground: AppColors.textSecondary,
                            onTap: () => Navigator.of(context).pop(false),
                          ),
                        ),
                        const SizedBox(width: AppDimens.space2),
                      ],
                      Expanded(
                        child: _Action(
                          label: confirmText,
                          background: tone == IamDialogTone.danger
                              ? AppColors.error600
                              : AppColors.primary,
                          foreground: AppColors.gray0,
                          onTap: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Text(
            label,
            style: AppTypography.bodyL.copyWith(
              height: 1,
              fontWeight: AppTypography.semibold,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
