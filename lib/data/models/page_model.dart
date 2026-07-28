import 'package:json_annotation/json_annotation.dart';

part 'page_model.g.dart';

/// 공통 페이지 응답 봉투 (REST §0).
///
/// `genericArgumentFactories: true` 덕분에 `Page<ChannelListItem>` 형태로
/// 그대로 쓸 수 있고, Retrofit이 아이템 fromJson을 넘겨준다.
///
/// ⚠️ 코드 생성 후에도 제네릭 해석이 깨지면, 해당 엔드포인트만
///    구체 클래스(`PageChannelListItem` 등)로 내리는 게 가장 빠른 우회다.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  genericArgumentFactories: true,
)
class Page<T> {
  const Page({
    this.content = const [],
    this.page = 0,
    this.size = 0,
    this.totalElements = 0,
    this.totalPages = 0,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  /// 무한 스크롤에서 다음 페이지가 있는지.
  bool get hasNext => page + 1 < totalPages;

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PageToJson(this, toJsonT);
}

/// 공통 에러 봉투 (REST §0) — `{ error: { code, message } }`.
@JsonSerializable()
class ApiErrorBody {
  const ApiErrorBody({required this.error});

  final ApiErrorDetail error;

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorBodyFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorBodyToJson(this);
}

@JsonSerializable()
class ApiErrorDetail {
  const ApiErrorDetail({required this.code, required this.message});

  final String code;
  final String message;

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDetailFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorDetailToJson(this);
}

/// 이미지 업로드 응답 (REST §2.1).
@JsonSerializable()
class ImageUploadResponse {
  const ImageUploadResponse({required this.url});

  final String url;

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$ImageUploadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ImageUploadResponseToJson(this);
}
