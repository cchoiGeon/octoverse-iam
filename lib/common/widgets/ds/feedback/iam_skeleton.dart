import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';

/// line 텍스트 줄 · block 큰 영역 · circle 아바타
enum IamSkeletonVariant { line, block, circle }

/// IamSkeleton — IAM DS · feedback
///
/// 로딩 자리표시. shimmer가 왼→오로 흐른다.
/// `IAM_web/src/components/ds/feedback/Skeleton.tsx` 이식.
///
/// 접근성: 화면 낭독기에는 숨기고(`ExcludeSemantics`), 시스템에서 애니메이션을
/// 끈 사용자에게는 정지된 회색 블록만 보여준다(웹 `prefers-reduced-motion`과 동일).
class IamSkeleton extends StatefulWidget {
  const IamSkeleton({
    super.key,
    this.variant = IamSkeletonVariant.line,
    this.width,
    this.height,
    this.radius,
  });

  const IamSkeleton.line({super.key, this.width, this.height, this.radius})
    : variant = IamSkeletonVariant.line;

  const IamSkeleton.block({super.key, this.width, this.height, this.radius})
    : variant = IamSkeletonVariant.block;

  const IamSkeleton.circle({super.key, this.width, this.height})
    : variant = IamSkeletonVariant.circle,
      radius = null;

  final IamSkeletonVariant variant;

  /// null이면 variant 기본값. line·block은 가로 100%로 늘어난다.
  final double? width;
  final double? height;
  final double? radius;

  @override
  State<IamSkeleton> createState() => _IamSkeletonState();
}

class _IamSkeletonState extends State<IamSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.skeleton,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (w, h, r) = switch (widget.variant) {
      IamSkeletonVariant.line => (
        widget.width,
        widget.height ?? 14.0,
        widget.radius ?? AppDimens.radiusXs,
      ),
      IamSkeletonVariant.block => (
        widget.width,
        widget.height ?? 80.0,
        widget.radius ?? AppDimens.radiusMd,
      ),
      IamSkeletonVariant.circle => (
        widget.width ?? 44.0,
        widget.height ?? widget.width ?? 44.0,
        // 원은 반지름을 지름의 절반으로 — BoxShape.circle과 같은 결과.
        (widget.width ?? 44.0) / 2,
      ),
    };

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return ExcludeSemantics(
      child: SizedBox(
        // line·block은 width가 null이면 부모 폭을 채운다(웹 `width: 100%`).
        width: w ?? double.infinity,
        height: h,
        child: reduceMotion
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(r),
                ),
              )
            : AnimatedBuilder(
                animation: _c,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        AppColors.gray100,
                        AppColors.gray200,
                        AppColors.gray100,
                      ],
                      stops: const [0.25, 0.37, 0.63],
                      transform: _SlideGradient(_c.value),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// 그라데이션을 가로로 흘려보낸다. 웹의 `background-position: 200% → -200%`
/// 애니메이션과 같은 효과를 Flutter 그라데이션 변환으로 낸다.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.t);

  /// 0 → 1
  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // -2배 폭에서 +2배 폭까지 이동 → 띠가 화면을 완전히 통과한다.
    final dx = bounds.width * (t * 4 - 2);
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// 참가자 리스트 로딩용 조합 스켈레톤.
/// 웹 `ProfileCardSkeleton`과 같은 구성이다.
class IamProfileCardSkeleton extends StatelessWidget {
  const IamProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IamSkeleton.circle(width: 56),
          SizedBox(width: AppDimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IamSkeleton(width: 80, height: 16),
                SizedBox(height: AppDimens.space2),
                IamSkeleton(width: 160, height: 12),
                SizedBox(height: AppDimens.space2 + 2),
                Row(
                  children: [
                    IamSkeleton(
                      width: 52,
                      height: 22,
                      radius: AppDimens.radiusPill,
                    ),
                    SizedBox(width: 6),
                    IamSkeleton(
                      width: 44,
                      height: 22,
                      radius: AppDimens.radiusPill,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
