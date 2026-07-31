import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// circle 프로필 · rounded 사각 · card 명함(가로 9:5, 폭 100%)
enum IamImageShape { circle, rounded, card }

/// IamImageUpload — IAM DS · forms
///
/// 이미지 선택 자리. 빈 상태는 점선, 선택되면 미리보기 + 카메라 배지.
/// `IAM_web/src/components/ds/forms/ImageUpload.tsx` 이식.
///
/// ⚠️ 파일 고르기는 **화면이 한다**(`image_picker`). DS는 표현만 담당해
/// 플랫폼 플러그인에 묶이지 않는다. [onPick]에서 피커를 띄우고 결과를
/// [preview]로 돌려주면 된다.
class IamImageUpload extends StatelessWidget {
  const IamImageUpload({
    super.key,
    this.preview,
    this.onPick,
    this.onRemove,
    this.label,
    this.hint = 'JPG·PNG · 5MB 이하',
    this.shape = IamImageShape.circle,
    this.size = 120,
    this.placeholder = '이미지 추가',
    this.required = false,
    this.error,
  });

  /// `FileImage` · `CachedNetworkImageProvider` 등 무엇이든 받는다.
  final ImageProvider? preview;

  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  final String? label;
  final String? hint;
  final IamImageShape shape;

  /// circle·rounded 일 때의 한 변 길이. card는 폭 100%라 무시된다.
  final double size;

  final String placeholder;

  /// 라벨 옆에 빨간 `*`를 붙인다(IamInput과 같은 규칙).
  final bool required;

  /// 검증 실패 문구. 있으면 [hint] 대신 빨강으로 보여준다.
  final String? error;

  bool get _isCard => shape == IamImageShape.card;

  @override
  Widget build(BuildContext context) {
    final radius = shape == IamImageShape.circle
        ? BorderRadius.circular(size)
        : BorderRadius.circular(AppDimens.radiusLg);

    final box = ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: preview != null ? AppColors.surfaceSunken : AppColors.iris50,
          borderRadius: radius,
          // 빈 상태는 점선이어야 하나 Flutter 기본 Border엔 dashed가 없다.
          // 실선 2px + iris300 으로 대체한다(시각 무게는 유사).
          border: Border.all(
            color: preview != null
                ? AppColors.borderDefault
                : AppColors.iris300,
            width: preview != null ? 1 : 2,
          ),
        ),
        child: preview != null
            ? Image(
                image: preview!,
                fit: _isCard ? BoxFit.contain : BoxFit.cover,
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IamIcon(
                      IamIconName.camera,
                      size: 28,
                      color: AppColors.iris600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isCard ? placeholder : '사진 추가',
                      style: AppTypography.caption.copyWith(
                        height: 1,
                        fontWeight: AppTypography.semibold,
                        color: AppColors.iris600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

    final target = Semantics(
      button: true,
      label: label ?? '이미지 선택',
      child: GestureDetector(
        onTap: onPick,
        child: Stack(
          children: [
            _isCard
                ? AspectRatio(aspectRatio: 9 / 5, child: box)
                : SizedBox(width: size, height: size, child: box),
            if (preview != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.overlayScrimStrong,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceCard, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const IamIcon(
                    IamIconName.camera,
                    size: 16,
                    color: AppColors.gray0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: _isCard
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        if (label != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: label,
                children: required
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error600),
                        ),
                      ]
                    : null,
              ),
              style: AppTypography.bodyS.copyWith(
                height: 1.3,
                fontWeight: AppTypography.semibold,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space2),
        ],
        _isCard ? target : Center(child: target),
        if (preview != null && onRemove != null)
          Align(
            alignment: _isCard ? Alignment.centerLeft : Alignment.center,
            child: GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space2,
                  horizontal: AppDimens.space3,
                ),
                child: Text(
                  '삭제',
                  style: AppTypography.caption.copyWith(
                    height: 1,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          )
        else if (preview == null && hint != null) ...[
          const SizedBox(height: AppDimens.space2),
          Text(
            hint!,
            style: AppTypography.caption.copyWith(
              height: 1.4,
              color: AppColors.textTertiary,
            ),
          ),
        ],
        // 에러는 힌트와 별개로 항상 보인다 — 미리보기가 있어도 사라지면 안 된다.
        if (error != null) ...[
          const SizedBox(height: AppDimens.space2),
          Align(
            alignment: _isCard ? Alignment.centerLeft : Alignment.center,
            child: Text(
              error!,
              style: AppTypography.caption.copyWith(
                height: 1.4,
                color: AppColors.error700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
