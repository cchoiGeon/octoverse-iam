import 'package:flutter/material.dart' show Material, MaterialType, showDialog;
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
      // ⚠️ `scopesRoute: true`면 `explicitChildNodes: true`가 **강제**다
      //    (rendering/object.dart의 assert). 빼면 다이얼로그를 띄우는 순간
      //    빌드가 터진다 — 로그아웃·모임 삭제 등 확인 다이얼로그 전부.
      //    스코프 노드가 자식 시맨틱스를 흡수하면 스크린리더가 본문·버튼을
      //    개별로 못 읽기 때문에 프레임워크가 막아 둔 것이다.
      explicitChildNodes: true,
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            // ⚠️ `showDialog`는 `Material`을 깔아주지 않는다
            //    (`showModalBottomSheet`는 깔아준다 — 그래서 시트는 멀쩡했다).
            //    Material 없이 두면 `WidgetsApp`의 "빠졌다" 표시용 기본
            //    TextStyle이 상속돼 **모든 글자에 노란 이중 밑줄**이 그려진다.
            //    배경·그림자는 아래 Container가 그리므로 타입은 transparency.
            child: Material(
              type: MaterialType.transparency,
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
