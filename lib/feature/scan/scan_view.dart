import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'scan_controller.dart';

/// J1·J2 QR 스캐너.
///
/// 라우트   : AppRoutes.scan
/// 웹 대응  : `IAM_web/src/app/(app)/scan/page.tsx`
/// 디자인   : Figma `QR 모임 참가` 보드 (510:1582 · 510:1600)
class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 카메라 화면이라 어두운 배경 — 뷰파인더가 또렷하게 보인다.
      backgroundColor: AppColors.gray900,
      body: Obx(
        () =>
            controller.unavailable.value != null ? _unavailable() : _scanner(),
      ),
    );
  }

  Widget _scanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            for (final b in capture.barcodes) {
              final raw = b.rawValue;
              if (raw != null) controller.onDetect(raw);
            }
          },
          errorBuilder: (_, error, __) {
            // 권한 거부·미지원은 렌더 중에 알 수 없어 여기서 잡는다.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => controller.onUnavailable(error.errorCode.name),
            );
            return const SizedBox.shrink();
          },
        ),
        SafeArea(
          child: Column(
            children: [
              _topBar(),
              const Spacer(),
              const _Viewfinder(),
              const SizedBox(height: AppDimens.space5),
              Text(
                'QR을 사각형 안에 맞춰주세요',
                style: AppTypography.body.copyWith(color: AppColors.gray0),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(AppDimens.gutterMobile),
                child: Text(
                  '카메라 화면은 이 기기에서만 처리되고 저장되지 않아요',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    height: 1.5,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space2),
      child: Row(
        children: [
          IamIconButton(
            icon: IamIconName.close,
            semanticLabel: '닫기',
            color: AppColors.gray0,
            onPressed: controller.goHome,
          ),
          Expanded(
            child: Text(
              '모임 참가',
              textAlign: TextAlign.center,
              style: AppTypography.title3.copyWith(color: AppColors.gray0),
            ),
          ),
          const SizedBox(width: AppDimens.touchMin),
        ],
      ),
    );
  }

  Widget _unavailable() {
    return SafeArea(
      child: ColoredBox(
        color: AppColors.surfacePage,
        child: Column(
          children: [
            IamAppHeader(
              title: '모임 참가',
              onBack: controller.goHome,
              variant: IamHeaderVariant.center,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.gutterMobile),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IamEmptyState(
                        icon: IamIconName.camera,
                        title: '카메라를 쓸 수 없어요',
                        description:
                            '브라우저·기기 설정에서 카메라를 허용하거나,\n모임 이름으로 검색해 참가할 수 있어요.',
                        action: IamButton(
                          label: '모임 이름으로 검색',
                          variant: IamButtonVariant.accent,
                          block: true,
                          onPressed: controller.goSearch,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 스캔 영역 표시 — 네 모서리 괄호.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 40.0;

    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(len * dx, 0), paint);
      canvas.drawLine(o, o.translate(0, len * dy), paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
