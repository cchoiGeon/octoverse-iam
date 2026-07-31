import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'me_profile_controller.dart';

/// 10 내 프로필 편집.
///
/// 라우트   : AppRoutes.meProfile
/// 웹 대응  : `IAM_web/src/app/(app)/me/profile/page.tsx`
/// 디자인   : Figma `3.UI` v3-03 (239:795)
class MeProfileView extends GetView<MeProfileController> {
  const MeProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '프로필 편집', onBack: Get.back),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isLoading.value
            ? const SizedBox.shrink()
            : IamBottomCTABar(
                children: [
                  Expanded(
                    child: IamButton(
                      label: '저장',
                      size: IamButtonSize.lg,
                      block: true,
                      loading: controller.isSaving.value,
                      onPressed: controller.save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: Column(
          children: [
            IamSkeleton.circle(width: 120),
            SizedBox(height: AppDimens.space5),
            IamSkeleton.block(height: 52),
            SizedBox(height: AppDimens.space4),
            IamSkeleton.block(height: 52),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space5,
        AppDimens.gutterMobile,
        AppDimens.space10,
      ),
      children: [
        Obx(
          () => IamImageUpload(
            preview: controller.newPhoto.value != null
                ? FileImage(controller.newPhoto.value!)
                : (controller.photoUrl.value != null
                          ? NetworkImage(controller.photoUrl.value!)
                          : null)
                      as ImageProvider?,
            onPick: controller.pickPhoto,
            onRemove: controller.removePhoto,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamInput(
            controller: controller.nickname,
            label: '닉네임',
            required: true,
            placeholder: '표시될 이름',
            maxLength: 30,
            error: controller.nicknameError.value,
            onChanged: (_) => controller.nicknameError.value = null,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        IamInput(
          controller: controller.oneLiner,
          label: '한 줄 소개',
          placeholder: '나를 한 문장으로',
          maxLength: kMaxOneLiner,
        ),
        const SizedBox(height: AppDimens.space5),
        IamTextarea(
          controller: controller.introduction,
          label: '자기소개',
          placeholder: '관심사·하는 일·만나고 싶은 사람 등',
          maxLength: kMaxIntroduction,
          rows: 5,
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '관심사',
            options: [
              for (final t in controller.interestOptions)
                IamTagOption('${t.id}', t.label),
            ],
            value: controller.interestIds.toList(),
            onChanged: (v) => controller.interestIds.value = v,
            max: kMaxInterests,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '보유 스킬',
            options: [
              for (final s in controller.skillOptions)
                IamTagOption(s.name, s.name),
            ],
            value: controller.skills.toList(),
            onChanged: (v) => controller.skills.value = v,
            max: kMaxSkills,
          ),
        ),
        const SizedBox(height: AppDimens.space6),
        _itemSections(),
      ],
    );
  }

  /// 경력·이력·링크 — 항목을 나열하고 각 카드에서 수정 화면으로 들어간다.
  /// 삭제는 수정 화면 안에 있다(웹 `CareerForm`의 삭제 버튼과 같다).
  Widget _itemSections() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(
            title: '경력',
            count: controller.careers.length,
            addLabel: '경력 추가',
            onAdd: controller.openCareer,
            children: [
              for (final (i, c) in controller.careers.indexed)
                _entryCard(
                  onEdit: () => controller.openCareer(i),
                  title: c.company,
                  subtitle: c.title,
                  meta: _careerPeriod(c),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space6),
          _section(
            title: '이력',
            count: controller.recordCount,
            addLabel: '이력 추가 (학력·자격증·수상·어학)',
            onAdd: controller.openRecord,
            children: _recordCards(),
          ),
          const SizedBox(height: AppDimens.space6),
          _section(
            title: '외부 링크',
            count: controller.links.length,
            addLabel: '링크 추가',
            onAdd: controller.openLink,
            children: [
              for (final (i, l) in controller.links.indexed)
                _entryCard(
                  onEdit: () => controller.openLink(i),
                  tag: l.type.label,
                  title: l.label ?? _domainOf(l.url),
                  meta: l.url,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4개 배열을 한 목록으로 합친다 — 사용자에겐 "이력" 하나로 보인다.
  List<Widget> _recordCards() => [
    for (final (i, e) in controller.educations.indexed)
      _entryCard(
        onEdit: () => controller.openRecord(RecordKind.education, i),
        tag: RecordKind.education.label,
        title: e.school ?? e.major ?? '학력',
        subtitle: [
          e.major,
          e.degree,
        ].where((s) => s != null && s.isNotEmpty).join(' · '),
        meta: _ymRange(e.startYearMonth, e.endYearMonth),
      ),
    for (final (i, c) in controller.certifications.indexed)
      _entryCard(
        onEdit: () => controller.openRecord(RecordKind.certification, i),
        tag: RecordKind.certification.label,
        title: c.name,
        subtitle: c.issuer,
        meta: _ym(c.acquiredDate),
      ),
    for (final (i, a) in controller.awards.indexed)
      _entryCard(
        onEdit: () => controller.openRecord(RecordKind.award, i),
        tag: RecordKind.award.label,
        title: a.name,
        subtitle: a.organization,
        meta: _ym(a.awardedDate),
      ),
    for (final (i, l) in controller.languages.indexed)
      _entryCard(
        onEdit: () => controller.openRecord(RecordKind.language, i),
        tag: RecordKind.language.label,
        title: l.language,
        subtitle: [
          l.level?.label,
          l.score,
        ].where((s) => s != null && s.isNotEmpty).join(' · '),
      ),
  ];

  Widget _section({
    required String title,
    required int count,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.body.copyWith(
                height: 1.3,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(width: AppDimens.space2),
            Text(
              '$count',
              style: AppTypography.caption.copyWith(
                height: 1,
                fontWeight: AppTypography.medium,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space3),
        for (final child in children) ...[
          child,
          const SizedBox(height: AppDimens.space3),
        ],
        _AddButton(label: addLabel, onTap: onAdd),
      ],
    );
  }

  /// 항목 한 줄 — 좌측 정보 + 우측 "수정".
  Widget _entryCard({
    required VoidCallback onEdit,
    required String title,
    String? tag,
    String? subtitle,
    String? meta,
  }) {
    final sub = (subtitle == null || subtitle.isEmpty) ? null : subtitle;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space3,
        horizontal: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag != null) ...[
                  IamTag(tag, size: IamTagSize.sm),
                  const SizedBox(height: AppDimens.space1),
                ],
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyS.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.semibold,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (meta != null && meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      height: 1.4,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Semantics(
            button: true,
            label: '$title 수정',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.space1),
                child: Text(
                  '수정',
                  style: AppTypography.caption.copyWith(
                    height: 1,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textLink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "2024.03 – 현재" / "2021.03 – 2024.02"
  String _careerPeriod(CareerItem c) {
    final start = _ym(c.startYearMonth);
    if (c.isCurrent) return '$start – 현재';
    final end = _ym(c.endYearMonth);
    return end == null ? (start ?? '') : '$start – $end';
  }

  String? _ymRange(String? start, String? end) {
    final s = _ym(start);
    final e = _ym(end);
    if (s == null && e == null) return null;
    return [s, e].where((v) => v != null).join(' – ');
  }

  /// "YYYY-MM" → "YYYY.MM" (웹 `fmtYm`과 같은 표기).
  String? _ym(String? v) =>
      (v == null || v.isEmpty) ? null : v.replaceAll('-', '.');

  String _domainOf(String url) => Uri.tryParse(url)?.host.isNotEmpty == true
      ? Uri.parse(url).host
      : url;
}

/// 점선 테두리 추가 버튼 — 웹 `AddButton` 대응.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space3),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IamIcon(
                IamIconName.plus,
                size: 16,
                color: AppColors.textLink,
              ),
              const SizedBox(width: AppDimens.space2),
              Text(
                label,
                style: AppTypography.bodyS.copyWith(
                  height: 1.3,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textLink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
