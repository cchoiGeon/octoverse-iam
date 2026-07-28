import 'package:json_annotation/json_annotation.dart';

/// 프로필(v3) 관련 enum — `IAM_web/src/types/api.ts` 이식.
/// v3에서 경력·이력이 4-카테고리 모델로 개편됐다(Figma `v3` 보드).

// ── 직무 카테고리 ────────────────────────────────────────────
/// ⚠️ 서버 enum에 `data`는 없다(Swagger 검증됨).
enum JobCategory {
  @JsonValue('planning')
  planning,
  @JsonValue('development')
  development,
  @JsonValue('design')
  design,
  @JsonValue('marketing')
  marketing,
  @JsonValue('sales')
  sales,
  @JsonValue('operation')
  operation,
  @JsonValue('etc')
  etc;

  String get label => switch (this) {
    JobCategory.planning => '기획·PM',
    JobCategory.development => '개발',
    JobCategory.design => '디자인',
    JobCategory.marketing => '마케팅',
    JobCategory.sales => '세일즈',
    JobCategory.operation => '운영',
    JobCategory.etc => '기타',
  };
}

// ── 외부 링크 종류 ───────────────────────────────────────────
enum LinkType {
  @JsonValue('sns')
  sns,
  @JsonValue('portfolio')
  portfolio,
  @JsonValue('blog')
  blog,
  @JsonValue('github')
  github,
  @JsonValue('other')
  other;

  String get label => switch (this) {
    LinkType.sns => 'SNS',
    LinkType.portfolio => '포트폴리오',
    LinkType.blog => '블로그',
    LinkType.github => 'GitHub',
    LinkType.other => '기타',
  };
}

// ── 어학 수준 ────────────────────────────────────────────────
enum LanguageLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('native')
  native;

  String get label => switch (this) {
    LanguageLevel.beginner => '초급',
    LanguageLevel.intermediate => '중급',
    LanguageLevel.advanced => '고급',
    LanguageLevel.native => '원어민',
  };
}

// ── 이력 카테고리 (UI 전용 — 서버 필드가 아니다) ──────────────
/// "이력 추가" 화면에서 무엇을 입력할지 고르는 용도.
/// 각각 프로필의 educations / certifications / awards / languages 배열로 간다.
enum RecordKind {
  education,
  certification,
  award,
  language;

  String get label => switch (this) {
    RecordKind.education => '학력',
    RecordKind.certification => '자격증',
    RecordKind.award => '수상',
    RecordKind.language => '어학',
  };
}
