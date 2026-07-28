import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
// `hide Page` — data_manager가 내보내는 페이징 DTO `Page<T>`와 이름이 겹친다.
import 'package:flutter/widgets.dart' hide Page;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

/// 포스터 배색 — 그라데이션 6종.
enum PosterHue { iris, coral, forest, amber, ink, light }

/// 홍보포스터 만들기.
///
/// 라우트   : AppRoutes.eventPoster
/// 웹 대응  : `IAM_web/src/components/app/poster/PosterEditor.tsx`
///
/// ⚠️ **이 화면은 Figma 시안이 없다.** 공유 시트의 진입점만 디자인돼 있어
///    웹 구현을 기준으로 옮겼다. 시안이 나오면 맞춰야 한다.
class EventPosterController extends GetxController {
  EventPosterController(this._api, this._reference, this._toast);

  final ApiClient _api;
  final ReferenceService _reference;
  final ToastService _toast;

  late final String slug = Get.parameters['slug'] ?? '';

  /// 캡처용 — 화면에 보이는 미리보기를 그대로 이미지로 뽑는다.
  final posterKey = GlobalKey();

  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();
  final Rx<PosterHue> hue = PosterHue.iris.obs;
  final RxBool showIntro = true.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool isSharing = false.obs;

  String get title => channel.value?.title ?? '';
  String get place => channel.value?.location ?? '';
  String get intro => channel.value?.description ?? '';

  String get dateLabel => channel.value == null
      ? ''
      : DateTimeUtils.eventRange(channel.value!.startAt, channel.value!.endAt);

  String get categoryLabel => channel.value == null
      ? ''
      : _reference.categoryLabel(channel.value!.category);

  /// 포스터에 넣는 참가 링크 = 참가 QR과 같은 주소.
  String get joinUrl => '$kWebOrigin/event/$slug';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      channel.value = await _api.channel(slug);
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// 미리보기 위젯을 PNG로 캡처해 공유 시트를 띄운다.
  Future<void> shareImage() async {
    if (isSharing.value) return;
    isSharing.value = true;
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast.error('포스터를 만들지 못했어요.');
        return;
      }
      // ⚠️ 바이트를 바로 넘기지 않고 임시 파일로 떨군다. share_plus 10.x의
      //    안드로이드 구현은 FileProvider로 **경로**를 넘기는 방식이라
      //    `XFile.fromData`(경로 없는 XFile)는 공유 대상 앱에서 열리지 않는다.
      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/iam-poster-$slug.png',
      ).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: title);
    } catch (e) {
      _toast.showError(e);
    } finally {
      isSharing.value = false;
    }
  }

  Future<Uint8List?> _capture() async {
    final ctx = posterKey.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    // 미리보기는 화면 폭에 맞춰 작게 그려지므로 3배로 키워 캡처한다.
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}
