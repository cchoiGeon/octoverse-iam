import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 이미지 저장·공유 — 포스터와 명함이 함께 쓴다.
///
/// 웹은 `downloadPosterFile`(a[download])과 `sharePosterFile`(Web Share API)로
/// 나뉘어 있었다. 앱에서는 각각 갤러리 저장(gal)과 시스템 공유 시트(share_plus)다.
///
/// 결과를 예외 대신 [ImageActionResult]로 돌려주는 이유: 호출부가 전부
/// "성공하면 토스트, 실패하면 다른 토스트"라서 try/catch를 매번 쓰게 하지 않으려는 것이다.
abstract final class ImageShareUtils {
  /// 원격 이미지를 바이트로 받아온다. 명함처럼 **이미 이미지인 것**은 캡처할
  /// 필요가 없어서 URL을 그대로 내려받는다(웹 `urlToBlob`과 같은 자리).
  ///
  /// 인터셉터가 붙지 않은 새 Dio를 쓴다 — 이미지 CDN에 Bearer를 실을 이유가 없고,
  /// 401 재시도 로직을 타서도 안 된다.
  static Future<Uint8List?> fetchImageBytes(String url) async {
    try {
      final res = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      return data == null ? null : Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  /// 파일명으로 쓸 수 있게 다듬는다(한글은 남긴다).
  static String slugify(String value, {String fallback = 'image'}) {
    final s = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^\w가-힣-]'), '');
    if (s.isEmpty) return fallback;
    return s.length > 24 ? s.substring(0, 24) : s;
  }

  /// PNG 바이트를 갤러리에 저장한다.
  ///
  /// 권한 요청은 gal이 내부에서 한다. 거부되면 [ImageActionResult.denied].
  static Future<ImageActionResult> saveToGallery(
    Uint8List bytes, {
    required String name,
  }) async {
    try {
      await Gal.putImageBytes(bytes, name: name);
      return ImageActionResult.done;
    } on GalException catch (e) {
      // 권한 거부는 "실패"라기보다 사용자의 선택이라 문구를 달리한다.
      return e.type == GalExceptionType.accessDenied
          ? ImageActionResult.denied
          : ImageActionResult.failed;
    } catch (_) {
      return ImageActionResult.failed;
    }
  }

  /// PNG 바이트를 시스템 공유 시트로 넘긴다.
  ///
  /// ⚠️ 바이트를 바로 넘기지 않고 임시 파일로 떨군다. share_plus 10.x의 안드로이드
  ///    구현은 FileProvider로 **경로**를 넘기는 방식이라 `XFile.fromData`(경로 없는
  ///    XFile)는 공유 대상 앱에서 열리지 않는다.
  static Future<ImageActionResult> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/$fileName.png',
      ).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: text);
      return ImageActionResult.done;
    } catch (_) {
      return ImageActionResult.failed;
    }
  }
}

enum ImageActionResult {
  done,

  /// 사진 접근 권한이 거부됐다.
  denied,
  failed,
}
