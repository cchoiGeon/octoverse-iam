import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
// `hide Page` — data_manager가 내보내는 페이징 DTO `Page<T>`와 이름이 겹친다.
import 'package:flutter/widgets.dart' hide Page;
import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/utils/image_share_utils.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/services.dart';

import 'poster_config.dart';

/// 홍보포스터 만들기.
///
/// 라우트   : AppRoutes.eventPoster
/// 웹 대응  : `IAM_web/src/components/app/poster/PosterEditor.tsx`
///
/// ⚠️ **이 화면은 Figma 시안이 없다.** 공유 시트의 진입점만 디자인돼 있어
///    웹 구현을 기준으로 옮겼다. 시안이 나오면 맞춰야 한다.
///
/// 색·레이아웃·크기·소개는 [PosterConfig]가 들고, 이 컨트롤러는 로딩·추천·
/// 캡처·저장/공유만 맡는다. 폰트 축은 옮기지 않았다(`poster_config.dart` 참고).
class EventPosterController extends GetxController {
  EventPosterController(this._api, this._reference, this._toast, this._auth);

  final ApiClient _api;
  final ReferenceService _reference;
  final ToastService _toast;
  final AuthService _auth;

  /// 주최자만 포스터를 만들 수 있다(웹 `<RequireOrganizer>` 대응).
  /// 미들웨어에서는 채널을 모르므로 로드 후 여기서 판정한다.
  final RxBool isOrganizer = true.obs;

  late final String slug = Get.parameters['slug'] ?? '';

  /// 캡처용 — 화면에 보이는 미리보기를 그대로 이미지로 뽑는다.
  final posterKey = GlobalKey();

  /// 소개 문구 편집기. [config]의 intro와 양방향으로 붙어 있다.
  final introController = TextEditingController();

  final Rxn<ChannelDetail> channel = Rxn<ChannelDetail>();

  /// 편집 상태. 채널을 불러오면 그 카테고리의 추천값으로 덮인다
  /// (여기 초기값은 로딩 중 한 프레임만 쓰인다).
  final Rx<PosterConfig> config = const PosterConfig(
    format: PosterColorFormat.gradient,
    hue: PosterHue.iris,
    layout: PosterLayout.editorial,
    titleScale: PosterTitleScale.m,
    intro: '',
    showIntro: false,
  ).obs;

  /// 편집 탭 — 0 색상 · 1 레이아웃 · 2 내용.
  final RxInt tab = 0.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool isBusy = false.obs;

  String get title => channel.value?.title ?? '';
  String get place => channel.value?.location ?? '';

  List<String> get interests => [
    for (final t in channel.value?.interests ?? const []) t.label,
  ];

  String get organizerName => channel.value?.organizer.nickname ?? '주최자';

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
      final c = await _api.channel(slug);
      channel.value = c;
      isOrganizer.value = _auth.isOrganizer(c.organizer.id);
      // 진입하자마자 카테고리에 맞는 추천 배색·레이아웃이 적용돼 있어야
      // "빈 캔버스에서 시작하는" 느낌이 안 든다.
      config.value = PosterPresets.recommend(c.category, c.description);
      introController.text = c.description;
    } catch (e) {
      error.value = ApiError.from(e).displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  void goDetail() => Get.offNamed(AppRoutes.eventDetailOf(slug));

  // ── 편집 ────────────────────────────────────────────────────

  void setColor(PosterColorFormat format, PosterHue hue) =>
      config.value = config.value.copyWith(format: format, hue: hue);

  void setLayout(PosterLayout layout) =>
      config.value = config.value.copyWith(layout: layout);

  void setTitleScale(PosterTitleScale scale) =>
      config.value = config.value.copyWith(titleScale: scale);

  void setShowIntro(bool value) =>
      config.value = config.value.copyWith(showIntro: value);

  void setIntro(String value) =>
      config.value = config.value.copyWith(intro: value);

  /// 지금 설정이 추천 그대로인가 — 헤더에 "추천" 표시를 띄울지 정한다.
  bool get isAtRecommended =>
      channel.value != null &&
      PosterPresets.isRecommended(config.value, channel.value!.category);

  /// 시각 설정만 추천으로 되돌린다. 편집한 소개는 남긴다.
  void restoreRecommended() {
    final c = channel.value;
    if (c == null) return;
    config.value = PosterPresets.restore(config.value, c.category);
  }

  // ── 저장 · 공유 ─────────────────────────────────────────────

  /// 갤러리에 저장.
  Future<void> save() => _run(save: true);

  /// 시스템 공유 시트.
  Future<void> share() => _run(save: false);

  Future<void> _run({required bool save}) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast.error('포스터를 만들지 못했어요.');
        return;
      }
      final name = 'iam-poster-$slug';
      final result = save
          ? await ImageShareUtils.saveToGallery(bytes, name: name)
          : await ImageShareUtils.shareImage(
              bytes,
              fileName: name,
              text: title,
            );

      switch (result) {
        case ImageActionResult.done:
          if (save) _toast.success('포스터를 저장했어요.');
        case ImageActionResult.denied:
          _toast.error('사진 접근 권한이 없어 저장하지 못했어요. 설정에서 허용해 주세요.');
        case ImageActionResult.failed:
          _toast.error(
            save
                ? '저장에 실패했어요. 잠시 후 다시 시도해 주세요.'
                : '공유에 실패했어요. 잠시 후 다시 시도해 주세요.',
          );
      }
    } finally {
      isBusy.value = false;
    }
  }

  /// 미리보기를 **정확히 1080×1080**으로 캡처한다.
  ///
  /// 미리보기는 화면 폭에 맞춰 작게 그려지므로, 고정 배율(예전의 `3`) 대신
  /// 실제 렌더 크기에서 필요한 배율을 역산한다. 기기 폭이 달라도 결과 파일은
  /// 항상 같은 크기다 — 웹이 오프스크린 1080 노드를 따로 두는 것과 같은 목적.
  Future<Uint8List?> _capture() async {
    final ctx = posterKey.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final width = boundary.size.width;
    if (width <= 0) return null;

    final image = await boundary.toImage(pixelRatio: _posterPx / width);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  /// 출력 한 변(px). 웹 `POSTER_SIZE`와 같은 값.
  static const double _posterPx = 1080;

  @override
  void onClose() {
    introController.dispose();
    super.onClose();
  }
}
