import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/badges/iam_tag.dart';
import 'package:iam/common/widgets/ds/core/iam_avatar.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';
import 'package:iam/data/enums/profile_enums.dart';

/// 상세에 표시할 경력 한 줄.
class ProfileCareerRow {
  const ProfileCareerRow({
    required this.company,
    this.title,
    this.period,
    this.current = false,
  });

  final String company;
  final String? title;
  final String? period;
  final bool current;
}

/// 상세에 표시할 이력 한 줄(학력·자격증·수상·어학 통합).
class ProfileRecordRow {
  const ProfileRecordRow({
    required this.kind,
    required this.title,
    this.subtitle,
  });

  /// "학력" · "자격증" 같은 카테고리 라벨.
  final String kind;
  final String title;
  final String? subtitle;
}

/// 상세에 표시할 외부 링크.
class ProfileLinkRow {
  const ProfileLinkRow({required this.type, required this.label, this.url});

  final LinkType type;
  final String label;
  final String? url;
}

/// IamProfileDetail — IAM DS · social
///
/// 프로필 상세 본문 — 소개 · 관심사 · 경력 · 이력 · 스킬 · 외부 링크.
/// 찜 버튼은 하단 CTA로 따로 배치한다.
///
/// `IAM_web/src/components/ds/social/ProfileDetail.tsx` 이식.
/// ⚠️ K2 — 인증 표식은 렌더하지 않는다.
class IamProfileDetail extends StatelessWidget {
  const IamProfileDetail({
    super.key,
    required this.name,
    this.photo,
    this.headline,
    this.introduction,
    this.tags = const [],
    this.careers = const [],
    this.records = const [],
    this.skills = const [],
    this.links = const [],
    this.onOpenLink,
  });

  final String name;
  final String? photo;
  final String? headline;
  final String? introduction;
  final List<String> tags;
  final List<ProfileCareerRow> careers;
  final List<ProfileRecordRow> records;
  final List<String> skills;
  final List<ProfileLinkRow> links;

  /// 링크 탭. DS는 url_launcher에 묶이지 않는다 — 화면이 연다.
  final ValueChanged<ProfileLinkRow>? onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gutterMobile,
        vertical: AppDimens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (introduction != null && introduction!.isNotEmpty)
            _section('소개', [
              Text(
                introduction!,
                style: AppTypography.body.copyWith(
                  height: 1.65,
                  color: AppColors.textSecondary,
                ),
              ),
            ]),
          if (tags.isNotEmpty) _section('관심사', [_tagWrap(tags)]),
          if (careers.isNotEmpty)
            _section('경력', [
              for (final c in careers) ...[
                _CareerCard(item: c),
                if (c != careers.last) const SizedBox(height: AppDimens.space4),
              ],
            ]),
          if (records.isNotEmpty)
            _section('이력', [
              for (final r in records) ...[
                _RecordRow(item: r),
                if (r != records.last) const SizedBox(height: AppDimens.space3),
              ],
            ]),
          if (skills.isNotEmpty) _section('스킬', [_tagWrap(skills)]),
          if (links.isNotEmpty)
            _section('외부 링크', [
              for (final l in links) ...[
                _LinkRow(item: l, onTap: onOpenLink),
                if (l != links.last) const SizedBox(height: AppDimens.space2),
              ],
            ]),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimens.space2,
        bottom: AppDimens.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // K2: verified 미전달
          IamAvatar(src: photo, name: name, size: 96),
          const SizedBox(height: AppDimens.space2),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTypography.title1.copyWith(height: 1.2),
          ),
          if (headline != null && headline!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                headline!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title3.copyWith(
              height: 1.4,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.18,
            ),
          ),
          const SizedBox(height: AppDimens.space2),
          ...children,
        ],
      ),
    );
  }

  Widget _tagWrap(List<String> items) => Wrap(
    spacing: AppDimens.space2,
    runSpacing: AppDimens.space2,
    children: [for (final t in items) IamTag(t)],
  );
}

class _CareerCard extends StatelessWidget {
  const _CareerCard({required this.item});

  final ProfileCareerRow item;

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (item.title != null) item.title!,
      if (item.period != null) item.period!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppDimens.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.iris50,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            alignment: Alignment.center,
            child: const IamIcon(
              IamIconName.briefcase,
              size: 18,
              color: AppColors.iris600,
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimens.space2,
                  runSpacing: AppDimens.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.company,
                      style: AppTypography.body.copyWith(
                        height: 1.4,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    if (item.current)
                      const IamTag(
                        '현직',
                        tone: IamTagTone.primary,
                        size: IamTagSize.sm,
                      ),
                  ],
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppTypography.bodyS.copyWith(
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.item});

  final ProfileRecordRow item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IamTag(item.kind, size: IamTagSize.sm),
        const SizedBox(width: AppDimens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTypography.body.copyWith(
                  height: 1.4,
                  fontWeight: AppTypography.medium,
                ),
              ),
              if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle!,
                  style: AppTypography.bodyS.copyWith(
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.item, this.onTap});

  final ProfileLinkRow item;
  final ValueChanged<ProfileLinkRow>? onTap;

  /// 아이콘 세트에 전용 글리프가 없어 대표 아이콘으로 매핑한다.
  /// SNS는 종류가 다양해 instagram URL일 때만 instagram, 나머지는 중립 user.
  IamIconName get _icon => switch (item.type) {
    LinkType.sns =>
      RegExp('instagram.com', caseSensitive: false).hasMatch(item.url ?? '')
          ? IamIconName.instagram
          : IamIconName.user,
    LinkType.portfolio => IamIconName.briefcase,
    _ => IamIconName.link,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.url == null || onTap == null ? null : () => onTap!(item),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimens.touchMin),
          padding: const EdgeInsets.all(AppDimens.space3),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            children: [
              IamIcon(_icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppDimens.space2),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
