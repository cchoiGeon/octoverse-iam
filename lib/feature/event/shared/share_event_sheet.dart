import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/channel_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/services.dart';

/// 모임 공유 시트 — 체크인 코드 / 홍보포스터 / 링크 복사 / 참가 QR.
///
/// 웹 대응: `IAM_web/src/components/app/ShareEventSheet.tsx`
///
/// 앱에 존재하는 QR은 **참가 QR 하나뿐**이다. 체크인엔 QR이 없고 6자리 코드만
/// 쓴다 — 두 개를 헷갈리면 참가자가 엉뚱한 화면에서 카메라를 든다.
abstract final class ShareEventSheet {
  /// [startAt]·[endAt]을 주면 체크인 창(시작 1시간 전 ~ 종료)일 때만
  /// "체크인 코드 열기"가 보인다. 안 주면 그 항목을 숨긴다.
  static Future<void> show(
    BuildContext context, {
    required String slug,
    required String title,
    String? startAt,
    String? endAt,
  }) {
    final url = '$kWebOrigin/event/$slug';
    final checkinOpen = startAt != null && endAt != null
        ? ChannelUtils.checkinWindow(startAt, endAt).isOpen
        : false;

    return IamBottomSheet.show<void>(
      context,
      title: '공유하기',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (checkinOpen)
            IamListItem(
              icon: IamIconName.keypad,
              title: '체크인 코드 열기',
              description: '체크인 가능 시간에만 표시 · 시작 1시간 전 ~ 종료 시간',
              onTap: () {
                Navigator.of(ctx).pop();
                Get.toNamed(AppRoutes.eventCheckinHostOf(slug));
              },
            ),
          IamListItem(
            icon: IamIconName.share,
            title: '홍보포스터 만들기',
            description: '모임을 알릴 이미지 포스터를 만들어요.',
            onTap: () {
              Navigator.of(ctx).pop();
              Get.toNamed(AppRoutes.eventPosterOf(slug));
            },
          ),
          IamListItem(
            icon: IamIconName.link,
            title: '링크 복사',
            description: url,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) Navigator.of(ctx).pop();
              Get.find<ToastService>().success('링크를 복사했어요.');
            },
          ),
          IamListItem(
            icon: IamIconName.qrCode,
            title: '참가 QR 보기',
            description: '모임에 초대할 때 쓰세요 · 스캔하면 이 모임으로 들어와요.',
            onTap: () {
              Navigator.of(ctx).pop();
              _showQr(context, url: url, title: title);
            },
          ),
        ],
      ),
    );
  }

  /// 웹은 시트를 갈아끼우지만(단일 라우트), 여기선 두 번째 시트를 새로 띄운다.
  ///
  /// 웹의 "QR 코드 저장"(다운로드 링크)은 옮기지 않았다. 앱에서 갤러리에 쓰려면
  /// 저장소 권한 + 별도 플러그인이 필요한데, 초대 링크는 "링크 복사"로,
  /// 이미지 공유는 홍보포스터로 이미 덮인다.
  static Future<void> _showQr(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    return IamBottomSheet.show<void>(
      context,
      title: title,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutterMobile,
          AppDimens.space2,
          AppDimens.gutterMobile,
          AppDimens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.space3),
              decoration: BoxDecoration(
                color: AppColors.gray0,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Semantics(
                label: '모임 참가 링크 QR 코드',
                image: true,
                child: QrImageView(
                  data: url,
                  size: 216,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space4),
            Text(
              url,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
